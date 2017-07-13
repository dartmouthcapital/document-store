# tmannherz/doc-store-base
FROM google/dart-runtime

COPY .* /app/
RUN chmod 777 /app/var
