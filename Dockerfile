FROM metabase/metabase:v0.65.0.8-beta

# psql and jq for the start script in .diploi/helm/app-scripts.yaml
USER root
RUN apk add --no-cache postgresql-client jq
USER 1000:1000
