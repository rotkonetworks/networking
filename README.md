# networking

we recently shifted our rpc infra from vrrp based loadbalancers to use higher availability anycast setup where each
node running haproxy announces ip and peers with route reflectors running on our ebgp routers to obtain all possible
routes via both device for maximizing redundancy and control. 

<img width="1308" height="816" alt="image" src="https://github.com/user-attachments/assets/83b1bc4c-faab-4135-97cd-1de2272d9efa" />
