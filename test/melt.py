import functools
import sys
from typing import Generator, List
import pytomlpp


def wrap_seq(sequence: str, margin: int) -> List[str]:
    def wrap(s: str, n: int) -> Generator[str, None, None]:
        while s:
            yield s[:n]
            s = s[n:]

    return list(wrap(sequence, margin))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python melt.py input.toml output.fasta", file=sys.stderr)
        exit(1)

    data = pytomlpp.load(sys.argv[1])
    with open(sys.argv[2], "w", encoding="utf-8") as output:
        output.write(
            "\n\n".join(
                map(
                    lambda id: f">{id}\n"
                    + "\n".join(
                        wrap_seq(
                            functools.reduce(
                                lambda acc, curr: acc
                                + curr["SequenceFragment"][len(curr["LeftOverlap"]) :],
                                data[id][1:],
                                data[id][0]["SequenceFragment"],
                            ),
                            60,
                        )
                    ),
                    data.keys(),
                )
            )
        )
