# FROM statement is only informational.
# The actual image used is defined in the BuildConfig.
FROM shared-services/openresty-nginx:1

# update and/or add nginx configurations
COPY nginx.conf /etc/nginx/nginx.conf
COPY modsecurity.conf /etc/nginx/modsecurity.conf
COPY crs-setup.conf /etc/nginx/crs/crs-setup.conf

# Lua sources
COPY lua/src /etc/nginx/lua

EXPOSE 8080

CMD nginx