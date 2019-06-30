# xsv-anylang

各種言語環境をコマンド一発でインストールから実行までできるようにするためのツール。


## Usage

    Usage:
        bash anylang.sh [OPTIONS] <COMMAND> [<ARG>...]
    
    Options:
        --prefx      インストールするディレクトリを指定 (デフォルトは $HOME/.xsvutils/anylang)
        --jdk=<VER>  インストールするopenjdkのバージョンを指定
        --sbt=<VER>  インストールするsbtのバージョンを指定。 --jdk も併せて指定が必要
        --graalvm=<VER>  インストールするGraalVMのバージョンを指定


## Example

Java

    $ bash ./anylang.sh --jdk=11 java -jar foo.jar

sbt

    $ bash ./anylang.sh --jdk=11 --sbt=1.2.8 sbt compile

GraalVM の native-image

    $ bash ./anylang.sh --graalvm=19.0.2 native-image -jar foo.jar

その場でインストールする言語環境に内部でPATHを通してから目的のコマンドを実行する。
以下の例では `foo.sh` の中でJDKに含まれる各種ツールを参照できる。

    $ bash ./anylang.sh --jdk=11 bash ./foo.sh


## Detail

必要な言語環境は `$HOME/.xsvutuils/anylang` にインストールされる。
または `--prefix` オプションを指定すればそのディレクトリにインストールされる。

指定の言語環境のバージョンがインストール済みであればそれをそのまま利用し、
未インストールであればその場でインストールしてから目的のコマンドを実行する。

対応している環境は以下

- JDK (Java)
- sbt (Scala)
- GraalVM
- Rust

今後対応したい環境は以下

- OCaml
- Go言語
- Ruby
- Python


## Install

`anylang.sh` 単独で動く。実行権限を付けてPATHを通せばどこからでも動かせる。

GraalVM の Native Image を使うには glibc-devel, zlib-devel が必要。
Ubuntuであれば、

    $ sudo apt-get install zlib1g-dev


## License

This software is released under the MIT License, see LICENSE.txt.

