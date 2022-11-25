FROM nginx:1.19.0-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d
COPY --from=ecsfargatepractice_app:latest /usr/src/app/staticfiles /usr/src/app/staticfiles
EXPOSE 80