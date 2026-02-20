# Engine Workspace

A Rails engine providing a three-panel accordion layout that composes page content, chat, and kanban views into a unified workspace.

## Panels

- **Page** - Primary content area for the active engine view
- **Chat** - Conversational interface powered by engine-llm
- **Kanban** - Plan and task management powered by engine-planner assertions

## Soft Dependencies

Engine Workspace composes functionality from other engines with graceful degradation:

- **engine-design-system** - Base layout, Tailwind config, and component helpers
- **engine-llm** - Chat panel (degrades to hidden panel if unavailable)
- **engine-planner** - Kanban panel with assertion framework (degrades to hidden panel if unavailable)

## Installation

Add to your Gemfile:

```ruby
gem "engine-workspace", path: "path/to/top/engine/engine-workspace"
```

Mount the engine:

```ruby
mount CoEngineWorkspace::Engine, at: "/workspace"
```

## Layout

Controllers rendering within the workspace use:

```ruby
layout "engine_workspace/application"
```

## Biological-IT Integration

All linkages between engine-workspace and other engines use library-biological (library-biological). Communication is by value through the MessageModerator, never by direct calls. Engine Workspace exposes the standard 6-method Bindable interface: create, read, update, delete, list, execute.

## License

The gem is available as open source under the terms of the MIT License.
