## Shosetsu Extensions - Extra

This path contains the extra files or a mirror API that I host on Glitch.

Base path: https://naotimes-og.glitch.me/shosetsu-api/

To access each API routes, you need to put the filename of each `.js` files and the following:
- `/` (GET)
  Shows the novels collection
- `/:id` (GET)
  Get the chapters list

For the passages, you need to process it directly in the lua extensions.

**JSON Schemas**<br />
- `/`

```jsonc
{
    "contents": [
        {
            "id": "url-path-based-id",
            "title": "Novel title",
            "authors": ["Author"], // list of string, might be an empty list
            "cover": null, // string or null
            "description": null, // string or null
            "status": -1,
        }
    ]
}
```

- `/:id`

```jsonc
{
    "contents": {
        "chapters": [
            {
                "order": 1,
                "id": "url-path-based-id",
                "title": "chapters title",
            }
        ],
        "novel": {
            "id": "url-path-based-id",
            "title": "Novel title",
            "authors": ["Author"], // list of string, might be an empty list
            "cover": null, // string or null
            "description": null, // string or null
            "status": -1,
        }
    }
}
```
