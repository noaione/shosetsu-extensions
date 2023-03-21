import json
from sh_index import (calculate_md5, extract_relevant_information, get_lib_dir,
                      get_root_dir, get_src_dir, peek_json)

ROOT_DIR = get_root_dir()
LIB_DIR = get_lib_dir()
SOURCES_DIR = get_src_dir()

index_metadata = {
    "libraries": [],
    "scripts": [],
}

print("Checking libraries...")
for library in LIB_DIR.glob("*.lua"):
    lib_data = peek_json(library)
    print("-- Valid library:", library.stem, f"(v{lib_data['ver']})")

print("Checking scripts/extensions...")
for source in SOURCES_DIR.rglob("*.lua"):
    src_data = peek_json(source)
    # Get name from lua file
    # Find the return string as the first
    name, img_url = extract_relevant_information(source)
    language = source.relative_to(SOURCES_DIR).as_posix().split("/")[0]
    schema = {
        "name": name,
        "fileName": source.stem,
        "imageURL": img_url,
        "id": src_data["id"],
        "lang": language,
        "ver": src_data["ver"],
        "libVer": src_data["libVer"],
        "md5": calculate_md5(source),
    }
    print("-- Valid script:", schema["name"], f"(v{schema['ver']})")

print("Checking dev index files...")
json.loads((ROOT_DIR / "index.json").read_text())
print("-- Valid index.json")
