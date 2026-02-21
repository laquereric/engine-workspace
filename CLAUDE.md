# Engine Workspace

Per-page layout engine with nav bar, chat IO, and bindable CRUD.

## Layout

`layouts/co_engine_workspace/application` — extends design-system layout with nav bar. Each page defines its own content structure.

### Pages

| Route | Content | Layout |
|-------|---------|--------|
| `/chat` | Full-page chat IO | Single column |
| `/dashboard` | Bindable count cards | Single column |
| `/:bindable_name` | Bindable list + chat IO | 2/3 + 1/3 grid |
| `/:bindable_name/:id` | Bindable detail + chat IO | 2/3 + 1/3 grid |

### Chat IO Partial

`_chat_io.html.erb` — reusable chat panel rendered on every page (as main content or side panel). Accepts optional `height` local (default: `h-full`).

## Using the Workspace Layout

Engines opt in by setting their layout:

```ruby
class MyController < ApplicationController
  layout "co_engine_workspace/application"
  include CoEngineWorkspace::Workspaceable
end
```

### Opt-out

Engines that don't want the workspace keep `layout "engine_design_system/application"`.
Per-action opt-out via `layout :choose_layout` method.

## Workspaceable Concern

`include CoEngineWorkspace::Workspaceable` provides:
- `workspace_context` — hash of engine, controller, action, record_id
- `workspace_conversation` — finds/creates page-scoped EngineLlm::Conversation

## Soft Dependencies

- **engine-llm**: chat panel. If not loaded, shows "Chat not available".
- **engine-design-system**: required. Provides nav bar, bindable components, and base layout.

## Stimulus Controllers

- `chat` — auto-scroll, Enter-to-submit, textarea auto-resize

## Table Prefix

No database tables — workspace is purely a layout/UI engine.
