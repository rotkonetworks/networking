use crate::types::{Action, PeerOrigin, RouterId};
use std::collections::HashMap;
use std::time::{Duration, Instant};
use tracing::debug;

/// state tracked per peer for hysteresis
#[derive(Debug, Clone)]
struct PeerHysteresisState {
    /// last action applied
    last_action: Action,
    /// when last action was applied
    last_change: Instant,
    /// current local_pref
    current_pref: u16,
    /// recent scores for smoothing
    score_history: Vec<(Instant, f64)>,
}

/// prevents flapping by requiring score delta and hold time
pub struct Hysteresis {
    /// minimum score difference to trigger change
    min_delta: f64,
    /// minimum time between changes for same peer
    hold_time: Duration,
    /// how long to keep score history
    history_window: Duration,
    /// state per peer
    state: HashMap<(RouterId, PeerOrigin), PeerHysteresisState>,
}

impl Hysteresis {
    pub fn new(min_delta: f64, hold_time: Duration) -> Self {
        Self {
            min_delta,
            hold_time,
            history_window: Duration::from_secs(300), // 5 min history
            state: HashMap::new(),
        }
    }

    /// record a new score observation
    pub fn observe(&mut self, router: RouterId, origin: PeerOrigin, score: f64) {
        let key = (router, origin);
        let now = Instant::now();

        let state = self.state.entry(key).or_insert_with(|| PeerHysteresisState {
            last_action: Action::Noop,
            last_change: now - self.hold_time * 2, // allow immediate first action
            current_pref: 100,
            score_history: Vec::new(),
        });

        // add to history
        state.score_history.push((now, score));

        // prune old entries
        let cutoff = now - self.history_window;
        state.score_history.retain(|(t, _)| *t > cutoff);
    }

    /// get smoothed score (exponential moving average)
    pub fn smoothed_score(&self, router: RouterId, origin: PeerOrigin) -> Option<f64> {
        let key = (router, origin);
        let state = self.state.get(&key)?;

        if state.score_history.is_empty() {
            return None;
        }

        // exponential moving average with recent bias
        let now = Instant::now();
        let mut weighted_sum = 0.0;
        let mut weight_sum = 0.0;

        for (time, score) in &state.score_history {
            let age = now.duration_since(*time).as_secs_f64();
            let weight = (-age / 60.0).exp(); // decay over 1 minute
            weighted_sum += score * weight;
            weight_sum += weight;
        }

        if weight_sum > 0.0 {
            Some(weighted_sum / weight_sum)
        } else {
            None
        }
    }

    /// check if a preference change should be applied
    pub fn should_change_pref(
        &self,
        router: RouterId,
        origin: PeerOrigin,
        new_pref: u16,
    ) -> bool {
        let key = (router, origin);

        match self.state.get(&key) {
            Some(state) => {
                // check hold time
                if state.last_change.elapsed() < self.hold_time {
                    debug!(
                        router = %router,
                        peer = %origin,
                        hold_remaining = ?(self.hold_time - state.last_change.elapsed()),
                        "hold time not expired"
                    );
                    return false;
                }

                // check delta
                let delta = (new_pref as i32 - state.current_pref as i32).abs();
                let pref_range = 100.0; // typical range 50-150
                let normalized_delta = delta as f64 / pref_range;

                if normalized_delta < self.min_delta {
                    debug!(
                        router = %router,
                        peer = %origin,
                        current = state.current_pref,
                        proposed = new_pref,
                        delta = normalized_delta,
                        min_delta = self.min_delta,
                        "delta below threshold"
                    );
                    return false;
                }

                true
            }
            None => true, // no state = first observation, allow
        }
    }

    /// record that an action was applied
    pub fn record_change(
        &mut self,
        router: RouterId,
        origin: PeerOrigin,
        action: Action,
        new_pref: u16,
    ) {
        let key = (router, origin);
        let now = Instant::now();

        let state = self.state.entry(key).or_insert_with(|| PeerHysteresisState {
            last_action: Action::Noop,
            last_change: now,
            current_pref: 100,
            score_history: Vec::new(),
        });

        state.last_action = action;
        state.last_change = now;
        state.current_pref = new_pref;
    }

    /// get current preference for a peer
    pub fn current_pref(&self, router: RouterId, origin: PeerOrigin) -> Option<u16> {
        let key = (router, origin);
        self.state.get(&key).map(|s| s.current_pref)
    }

    /// get time since last change
    pub fn time_since_change(&self, router: RouterId, origin: PeerOrigin) -> Option<Duration> {
        let key = (router, origin);
        self.state.get(&key).map(|s| s.last_change.elapsed())
    }

    /// check if peer is in "cooling off" period
    pub fn is_cooling(&self, router: RouterId, origin: PeerOrigin) -> bool {
        let key = (router, origin);
        self.state
            .get(&key)
            .map(|s| s.last_change.elapsed() < self.hold_time)
            .unwrap_or(false)
    }

    /// get all peers currently in hold period
    pub fn peers_in_hold(&self) -> Vec<(RouterId, PeerOrigin)> {
        self.state
            .iter()
            .filter(|(_, s)| s.last_change.elapsed() < self.hold_time)
            .map(|(k, _)| *k)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hold_time() {
        let mut h = Hysteresis::new(0.1, Duration::from_secs(60));

        let router = RouterId::Bkk00;
        let origin = PeerOrigin::Bknix;

        // first observation, should allow change
        h.observe(router, origin, 0.8);
        assert!(h.should_change_pref(router, origin, 120));

        // record change
        h.record_change(router, origin, Action::Noop, 120);

        // immediate second change should be blocked
        assert!(!h.should_change_pref(router, origin, 80));
    }

    #[test]
    fn test_min_delta() {
        let mut h = Hysteresis::new(0.2, Duration::from_millis(1));

        let router = RouterId::Bkk00;
        let origin = PeerOrigin::HgcHk;

        h.observe(router, origin, 0.7);
        h.record_change(router, origin, Action::Noop, 100);

        // wait for hold time
        std::thread::sleep(Duration::from_millis(10));

        // small change should be blocked (delta 0.05)
        assert!(!h.should_change_pref(router, origin, 105));

        // large change should be allowed (delta 0.3)
        assert!(h.should_change_pref(router, origin, 130));
    }
}
