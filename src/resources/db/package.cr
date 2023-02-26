require "mysql"

require "./inflater/*"
require "./query/*"

module Sharock::Resources::DB
  class PackageResource
    include Inflater::Package
    include Query::Select

    def initialize(@conn : MySQL::Connection)
    end

    def find
      inflate _select(@conn, "package")
    end

    def find_by_ids(ids, for_update = false)
      inflate _select_by_ids(@conn, "package", ids, for_update)
    end

    def find_one_by_id(id, for_update = false)
      inflate_one _select_by_id(@conn, "package", id, for_update)
    end

    def find_one(host, owner, repo, for_update = false)
      inflate_one _select_by_repo(host, owner, repo, for_update)
    end

    def find_or_create(host, owner, repo, for_update = false)
      rows = _select_by_repo(host, owner, repo)
      if rows == [] of Entities::Rows::Package
        insert_by_repo(host, owner, repo)
      end

      inflate_one _select_by_repo(host, owner, repo, for_update)
    end

    def update_sync_started_at(id, sync_started_at)
      params = {"id" => id, "sync_started_at" => sync_started_at}
      ::MySQL::Query
        .new(%{
          UPDATE `package`
          SET sync_started_at = :sync_started_at
          WHERE `id` = :id
        }, params)
        .run(@conn)
    end

    protected def insert_by_repo(host, owner, repo)
      params = {"host" => host, "owner" => owner, "repo" => repo}
      ::MySQL::Query
        .new(%{
          INSERT INTO `package` (`host`, `owner`, `repo`)
          VALUES (:host, :owner, :repo)
          ON DUPLICATE KEY UPDATE
            `host` = :host, `owner` = :owner, `repo` = :repo
        }, params)
        .run(@conn)
    end

    protected def _select_by_repo(host, owner, repo, for_update = false)
      for_update = for_update ? "FOR UPDATE" : ""
      params = {"host" => host, "owner" => owner, "repo" => repo}
      ::MySQL::Query
        .new(%{
          SELECT *
          FROM `package`
          WHERE `host` = :host AND `owner` = :owner AND `repo` = :repo
          LIMIT 1
          #{for_update}
        }, params)
        .run(@conn)
    end
  end
end
