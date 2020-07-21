FROM alpine as intermediate
#maintenaier MFI
# Add metadata identifying these images as our build containers (this will be useful later!)
LABEL stage=intermediate

# Take an SSH key as a build argument.
ARG SSH_PRIVATE_KEY

# Install dependencies required to git clone.
RUN apk update && \
    apk add --update git && \
    apk add --update openssh

# 1. Create the SSH directory.
# 2. Populate the private key file.
# 3. Set the required permissions.
# 4. Add github to our list of known hosts for ssh.
RUN mkdir -p /root/.ssh/
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan -H github.com >> /root/.ssh/known_hosts
RUN git clone https://github.com/misterfifi1/hello_live.git git

# stage1 - build react app first
FROM node:12.16.1-alpine3.9 as build
COPY --from=intermediate git/ /app/
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
RUN yarn --silent
COPY . /app
RUN yarn build

# stage 2 - build the final image and copy the react build files
FROM nginx:1.17.8-alpine
COPY --from=build /app/build /usr/share/nginx/html
#RUN rm /etc/nginx/conf.d/default.conf
#COPY nginx/nginx.conf /etc/nginx/conf.d
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
