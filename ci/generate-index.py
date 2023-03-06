import json
from pathlib import Path
from hashlib import md5

ROOT_DIR = Path(__file__).absolute().parent.parent

LIB_DIR = ROOT_DIR / "lib"
SOURCES_DIR = ROOT_DIR / "src"

index_metadata = {
    "libraries": [],
    "scripts": [],
}


def peek_json(path: Path):
    # read first line
    with path.open("r") as fp:
        line = fp.readline()
    # strip comment
    line = line.lstrip("--")
    if line.startswith("-"):
        line = line[1:]
    # parse json
    return json.loads(line.strip())


def extract_relevant_information(path: Path):
    lua_data = path.read_text().splitlines()
    start_from = -1
    for idx, line in enumerate(lua_data):
        if line.startswith("return"):
            start_from = idx
            break
    if start_from == -1:
        raise ValueError("LUA file does not have a global return statement")
    name_found = None
    image_url_found = None
    for line in lua_data[start_from:]:
        if name_found is None and line.strip().startswith("name"):
            name_found = line.split("=", 1)[1].strip().strip(",")[1:-1]
        if image_url_found is None and line.strip().startswith("imageURL"):
            image_url_found = line.split("=", 1)[1].strip().strip(",")[1:-1]
    if name_found is None:
        raise ValueError("LUA file does not have a name field in the return statement")
    if image_url_found is not None and not image_url_found.startswith("http"):
        raise ValueError("Image URL from LUA file must be an HTTP(s) link")
    return name_found, image_url_found


def calculate_md5(path: Path):
    return md5(path.read_bytes()).hexdigest()


print("Collecting libraries...")
for library in LIB_DIR.glob("*.lua"):
    lib_data = peek_json(library)
    index_metadata["libraries"].append({
        "name": library.stem,
        "ver": lib_data["ver"],
    })

print("Collecting scripts/extensions...")
for source in SOURCES_DIR.rglob("*.lua"):
    print(f"-- Peeking {source}")
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
    index_metadata["scripts"].append(schema)

print("Writing generated files...")
(ROOT_DIR / "final" / "index.json").write_text(
    json.dumps(index_metadata, ensure_ascii=False, indent=2)
)
