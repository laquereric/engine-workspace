# Engine Workspace

Three-panel accordion layout composing page + chat + kanban into a unified workspace.

## Layout

`layouts/engine_workspace/application` — extends design-system layout, wraps yield in ds_accordion:
- **Page** panel (open by default) — host engine's view content
- **Chat** panel (collapsed) — engine-llm conversation scoped to current page
- **Tasks** panel (collapsed) — engine-planner assertions in kanban board

## Using the Workspace Layout

Engines opt in by setting their layout:

```ruby
class MyController < ApplicationController
  layout "engine_workspace/application"
  include EngineWorkspace::Workspaceable
end
```

### Opt-out

Engines that don't want the workspace keep `layout "engine_design_system/application"`.
Per-action opt-out via `layout :choose_layout` method.

## Workspaceable Concern

`include EngineWorkspace::Workspaceable` provides:
- `workspace_context` — hash of engine, controller, action, record_id
- `workspace_conversation` — finds/creates page-scoped EngineLlm::Conversation
- `workspace_assertions` — planner assertions for current context
- `workspace_plan` — active Planner::Plan for current engine

## Soft Dependencies

- **engine-llm**: chat panel. If not loaded, shows "Chat not available".
- **engine-planner**: kanban panel. If not loaded, shows "Tasks not available".
- **engine-design-system**: required. Provides accordion component and base layout.

## Stimulus Controllers

- `accordion` — expand/collapse, localStorage persistence, single-open mode
- `chat` — auto-scroll, Enter-to-submit, textarea auto-resize
- `kanban` — card click navigates to planner assertion detail

## Table Prefix

No database tables — workspace is purely a layout/UI engine.
