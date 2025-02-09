#!/usr/bin/env python3
import argparse
import re
import urllib.request
from pathlib import Path

def get_public_ip():
    try:
        return urllib.request.urlopen('http://ifconfig.me/ip').read().decode('utf-8').strip()
    except Exception as e:
        print(f"Error fetching public IP: {e}")
        return None

def parse_config(config_path, server_ip):
    proxy_port = None
    users = []

    with open(config_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("proxy "):
                port_match = re.search(r'-p(\d+)', line)
                if port_match:
                    proxy_port = port_match.group(1)
            elif line.startswith("users "):
                parts = line.split()
                if len(parts) < 2:
                    continue
                credentials = parts[1].split(':')
                if len(credentials) >= 3:
                    users.append({
                        'username': credentials[0],
                        'password': credentials[2]
                    })

    return {
        'server_ip': server_ip,
        'server_port': proxy_port,
        'users': users
    }

def generate_user_card(user):
    return f"""
        <div class="user-card">
            <div class="label">Username</div>
            <div class="value">{user['username']}</div>
            <div class="label">Password</div>
            <div class="value">{user['password']}</div>
            <button class="copy-btn" 
                data-username="{user['username']}" 
                data-password="{user['password']}">
                Copy Config
            </button>
        </div>
    """

def generate_html(data, template_path, output_path):
    # Read template file
    with open(template_path, 'r') as f:
        template = f.read()

    # Generate users HTML
    users_html = "".join(generate_user_card(user) for user in data['users'])

    # Fill template
    html_content = template.format(
        server_ip=data['server_ip'],
        server_port=data['server_port'],
        user_count=len(data['users']),
        users_html=users_html
    )

    # Create output directory if it doesn't exist
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    # Write output file
    with open(output_path, 'w') as f:
        f.write(html_content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate 3Proxy status page')
    parser.add_argument('-c', '--config', nargs='?', default='3proxy.cfg', help='Path to 3proxy.cfg (optional, 3proxy.cfg will be used by default)')
    parser.add_argument('-t', '--template', nargs='?', default='template.html', help='Path to HTML template file (optional, template.html will be used by default)')
    parser.add_argument('-o', '--output', required=True, help='Output HTML file path')
    parser.add_argument('-i', '--ip', help='Server public IP address (optional, will be detected automatically)')
    args = parser.parse_args()

    # Get server IP
    server_ip = args.ip if args.ip else get_public_ip()
    if not server_ip:
        raise ValueError("Could not determine server IP address")

    config_data = parse_config(args.config, server_ip)
    
    if not config_data['server_port']:
        raise ValueError("Proxy port not found in config file")
    
    generate_html(config_data, args.template, args.output)
    print(f"Successfully generated status page at {args.output}")
