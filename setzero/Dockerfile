FROM sameersbn/gitlab:11.9.8

COPY setzero/customize_oauth.rb /home/git/gitlab/config/initializers/
COPY assets/runtime /etc/docker-gitlab/runtime
COPY entrypoint.sh /sbin/entrypoint.sh

# Issues https://gitlab.com/gitlab-org/gitlab-ce/issues/43514
# Mysql2::Error: Data too long for column 'query' at row 1: INSERT INTO `prometheus_metrics`
# Issues https://gitlab.com/gitlab-org/gitlab-ce/issues/49583
RUN chmod 755 /sbin/entrypoint.sh && \
    sed -i 's/create_table.*/create_table :lfs_file_locks, options: '"'ROW_FORMAT=DYNAMIC'"' do |t|/' /home/git/gitlab/db/migrate/20180116193854_create_lfs_file_locks.rb && \
    sed -i 's/t.string :query/t.text :query/' /home/git/gitlab/db/migrate/20180101160629_create_prometheus_metrics.rb && \
    sed -i 's/t.string "query"/t.text "query"/' /home/git/gitlab/db/schema.rb