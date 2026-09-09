/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("todos");

  // 追加 Agent 专属规格字段
  collection.fields.add(new BoolField({
    name: "is_agent",
    required: false,
  }));

  collection.fields.add(new TextField({
    name: "work_dir",
    required: false,
  }));

  collection.fields.add(new TextField({
    name: "model",
    required: false,
  }));

  collection.fields.add(new NumberField({
    name: "max_steps",
    required: false,
  }));

  collection.fields.add(new TextField({
    name: "agent_log",
    required: false,
  }));

  app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("todos");
  collection.fields.removeByName("is_agent");
  collection.fields.removeByName("work_dir");
  collection.fields.removeByName("model");
  collection.fields.removeByName("max_steps");
  collection.fields.removeByName("agent_log");
  app.save(collection);
});
