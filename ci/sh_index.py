import json
from pathlib import Path
from hashlib import md5


def get_root_dir():
    return Path(__file__).absolute().parent.parent


def get_lib_dir():
    return get_root_dir() / "lib"


def get_src_dir():
    return get_root_dir() / "src"


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
