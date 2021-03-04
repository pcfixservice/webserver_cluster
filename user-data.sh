#!/bin/bash
cat > index.html <<EOF
<h1>Hello, World</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF
nohup busybox httpd -f -p ${server_port} &


#It looks up variables using Terraform’s standard interpolation
#syntax, but the only available variables are the ones in the
#vars map of the template_file data source. Note that
#you don’t need any prefix to access those variables: e.g., you
#should use server_port and not var.server_port.

