FROM google/dart-runtime
LABEL maintainer="todd.mannherz@gmail.com"

COPY .* /app/
RUN chmod 777 /app/var
