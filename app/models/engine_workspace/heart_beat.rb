# frozen_string_literal: true

module EngineWorkspace
  class HeartBeat < ApplicationRecord
    include LibraryHeartbeat::HeartBeatConcern

    self.table_name = "engine_workspace_heartbeats"
  end
end
