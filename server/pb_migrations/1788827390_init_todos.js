/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    name: "todos",
    type: "base",
    listRule: "",
    viewRule: "",
    createRule: "",
    updateRule: "",
    deleteRule: "",
    fields: [
      {
        name: "title",
        type: "text",
        required: true,
      },
      {
        name: "description",
        type: "text",
      },
      {
        name: "status",
        type: "select",
        values: ["todo", "in_progress", "done"],
        maxSelect: 1,
        required: true,
      },
      {
        name: "priority",
        type: "number",
      },
      {
        name: "order",
        type: "number",
      },
      {
        name: "due_date",
        type: "text",
      },
    ],
  });
  app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("todos");
  if (collection) {
    app.delete(collection);
  }
});
