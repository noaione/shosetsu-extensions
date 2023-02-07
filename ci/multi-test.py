import argparse
import asyncio
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

ROOT_DIR = Path(__file__).absolute().parent.parent


class ExtensionNamespace(argparse.Namespace):
    # Print out loaded listings
    print_listings = False
    # Print out stats of listings
    print_list_stats = False
    # Print out loaded novels
    print_novels = False
    # Print out stats of loaded novels
    print_novel_stats = False
    # Print out passages
    print_passages = False
    # Print out repository index
    print_index = False
    # Print out metadata of an extension
    print_meta = False
    # Repeat a result, as sometimes there is an obscure error with reruns
    repeat = False
    # Test all loaded novels
    test_all_novels = False
    # Target a specific novel
    target_novel: Optional[str] = None
    # Target a specific chapter of a specific novel
    target_chapter: Optional[str] = None
    # Ignore missing novels (useful for testing a lot of novels)
    ignore_missing = False


def should_test_extension(extension_path: Path):
    if not extension_path.exists():
        return False
    if not extension_path.is_file():
        return False
    read_ext = extension_path.read_text()
    if "Require" in read_ext and (
        "Madara" in read_ext
        or "NovelFull" in read_ext
        or "247truyen" in read_ext
        or "WWVolare" in read_ext
    ):
        return False
    return True


parser = argparse.ArgumentParser()
parser.add_argument("--print-listings", action="store_true", help="Print out loaded listings")
parser.add_argument("--print-list-stats", action="store_true", help="Print out stats of listings")
parser.add_argument("--print-novels", action="store_true", help="Print out loaded novels")
parser.add_argument("--print-novel-stats", action="store_true", help="Print out stats of loaded novels")
parser.add_argument("--print-passages", action="store_true", help="Print out passages")
parser.add_argument("--print-index", action="store_true", help="Print out repository index")
parser.add_argument("--print-meta", action="store_true", help="Print out metadata of an extension")
parser.add_argument(
    "--repeat",
    action="store_true",
    help="Repeat a result, as sometimes there is an obscure error with reruns"
)
parser.add_argument("--test-all-novels", action="store_true", help="Test all loaded novels")
parser.add_argument("--target-novel", type=str, help="Target a specific novel")
parser.add_argument("--target-chapter", type=str, help="Target a specific chapter of a specific novel")
parser.add_argument(
    "--ignore-missing",
    action="store_true",
    help="Ignore missing novels (useful for testing a lot of novels)"
)
args = parser.parse_args(namespace=ExtensionNamespace())


index_file = ROOT_DIR / "index.json"
index_metadata = json.loads(index_file.read_bytes())

SOURCE_FOLDER = ROOT_DIR / "src"

scripts = index_metadata["scripts"]
scripts.sort(key=lambda x: x["fileName"])
extension_jar = ROOT_DIR / "extension-tester.jar"


@dataclass
class RunReesult:
    success: bool
    name: str


async def test_extension(script: dict) -> Optional[RunReesult]:
    name = script["name"]
    filename: str = script["fileName"]
    language: str = script["lang"]
    disable_test: bool = script.get("disableTest", False)
    print(f" ∟ Trying to test {name}")
    target_path = SOURCE_FOLDER / language / f"{filename}.lua"
    if not should_test_extension(target_path) or disable_test:
        print(f"   ∟ Skipping {name}")
        return None
    build_cmds = [
        "java",
        "-jar",
        str(extension_jar),
        str(target_path),
    ]
    if args.print_listings:
        build_cmds.append("--print-listings")
    if args.print_list_stats:
        build_cmds.append("--print-list-stats")
    if args.print_novels:
        build_cmds.append("--print-novels")
    if args.print_novel_stats:
        build_cmds.append("--print-novel-stats")
    if args.print_passages:
        build_cmds.append("--print-passages")
    if args.print_index:
        build_cmds.append("--print-index")
    if args.print_meta:
        build_cmds.append("--print-meta")
    if args.repeat:
        build_cmds.append("--repeat")
    if args.test_all_novels:
        build_cmds.append("--test-all-novels")
    if args.target_novel:
        build_cmds.append("--target-novel")
        build_cmds.append(args.target_novel)
    if args.target_chapter:
        build_cmds.append("--target-chapter")
        build_cmds.append(args.target_chapter)
    if args.ignore_missing:
        build_cmds.append("--ignore-missing")

    print(f"   ∟ Testing: {name}")
    proc = await asyncio.create_subprocess_shell(" ".join(build_cmds))
    returncode = await proc.wait()
    if returncode != 0:
        print(f"   ∟ Failed to test {name}")
        return RunReesult(False, name)
    else:
        print(f"   ∟ Finished testing {name}")
        return RunReesult(True, name)


print("—  Starting Test")
loop = asyncio.get_event_loop()
tasks = [
    test_extension(script)
    for script in scripts
]
results = loop.run_until_complete(asyncio.gather(*tasks))
failed_to_run = [result.name for result in results if result is not None and not result.success]

if failed_to_run:
    print("—  Failed to test the following extensions:")
    for name in failed_to_run:
        print(f" ∟ {name}")
    exit(1)
else:
    print("—  Finished Testing")
