import urllib3
import json
import sys

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Target IP to block
target_ip = sys.argv[1] if len(sys.argv) > 1 else "8.8.8.8"

# 1. Authenticate to get token
auth_url = "https://localhost:55000/security/user/authenticate"
headers = urllib3.make_headers(basic_auth="wazuh:xVd4N8CXeEfucpXmWuVlVhMo.awg2f.4")

http = urllib3.PoolManager(cert_reqs='CERT_NONE')
r = http.request('GET', auth_url, headers=headers)

if r.status != 200:
    print(f"Auth failed: {r.status} - {r.data.decode('utf-8')}")
    sys.exit(1)

token = json.loads(r.data.decode('utf-8'))['data']['token']

# 2. Trigger Active Response
ar_url = "https://localhost:55000/active-response?agents_list=003"
ar_headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

payload = {
    "command": "firewall-drop300",
    "alert": {
        "data": {
            "srcip": target_ip
        }
    }
}

r_ar = http.request('PUT', ar_url, headers=ar_headers, body=json.dumps(payload))

print(f"Status: {r_ar.status}")
print(r_ar.data.decode('utf-8'))
