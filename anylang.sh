#!/bin/bash

set -Ceu
# -C リダイレクトでファイルを上書きしない
# -e コマンドの終了コードが1つでも0以外になったら直ちに終了する
# -u 設定されていない変数が参照されたらエラー

usage() {
  cat <<\EOF >&2
各種言語環境をインストールし、コマンドを実行します。

$HOME/.xsv-anylang または --prefix オプションで指定したディレクトリに
オプションで指定した言語のバージョンをインストールし、PATHを通した上でコマンドを実行します。

Usage:
    anylang [OPTIONS] <COMMAND> [<ARG>...]

Options:
    --prefx      インストールするディレクトリを指定 (デフォルトは $HOME/.xsv-anylang)
    --jdk=<VER>  インストールするopenjdkのバージョンを指定
    --sbt=<VER>  インストールするsbtのバージョンを指定。 --jdk も併せて指定が必要

jdk
ex) --jdk=11

sbt
https://www.scala-sbt.org/download.html
ex) --sbt=1.2.8
EOF
  exit 1
}

while [ "$#" != 0 ]; do
    case "$1" in
        --prefix=* )
            PREFIX="${1#*=}"
            ;;
        --jdk=* )
            JDK_VERSION="${1#*=}"
            ;;
        --sbt=* )
            SBT_VERSION="${1#*=}"
            ;;
        --* )
            echo "Option \`${1}\` is not supported." >&1
            exit 1
            ;;
        * )
            break
    esac
    shift
done

: "${PREFIX:=$HOME/.xsv-anylang}"

################################################################################
# jdk
################################################################################

install_jdk() {
    if [ ! -x "$PREFIX/jdk-${JDK_VERSION}/bin/java" ]; then
        uname=$(uname)
        if [ "$uname" = "Darwin" ]; then
            openjdk_os_name='osx'
        elif [ "$uname" = "Linux" ]; then
            openjdk_os_name='linux'
        else
            echo "Unknown OS: $uname" >&2
            exit 1
        fi

        tmppath="$PREFIX/jdk-${JDK_VERSION}-$$"
        mkdir -p $tmppath
        url="https://download.java.net/java/ga/jdk${JDK_VERSION}/openjdk-${JDK_VERSION}_${openjdk_os_name}-x64_bin.tar.gz"

        echo "cd $tmppath; curl -L $url | tar xzf -"
        (
            cd $tmppath
            curl -L $url | tar xzf -
        )
        if [ ! -e "$PREFIX/jdk-${JDK_VERSION}/bin/java" ]; then
            if [ -e "$PREFIX/jdk-${JDK_VERSION}" ]; then
                rm -rf "$PREFIX/jdk-${JDK_VERSION}"
            fi
            if [ $openjdk_os_name = "osx" ]; then
                echo mv $tmppath/jdk-$JDK_VERSION.jdk "$PREFIX/jdk-${JDK_VERSION}"
                mv $tmppath/jdk-$JDK_VERSION.jdk "$PREFIX/jdk-${JDK_VERSION}"
            else
                echo mv $tmppath/jdk-$JDK_VERSION "$PREFIX/jdk-${JDK_VERSION}"
                mv $tmppath/jdk-$JDK_VERSION "$PREFIX/jdk-${JDK_VERSION}"
            fi
        fi
        rm -rf $tmppath
    fi

    export PATH="$PREFIX/jdk-${JDK_VERSION}/bin:$PATH"
}

################################################################################
# sbt
################################################################################

install_sbt() {
    if [ ! -v JDK_VERSION ]; then
        echo "use --jdk=* option" >&2
        exit 1
    fi

    if [ ! -x "$PREFIX/sbt-${SBT_VERSION}/bin/sbt" ]; then
        tmppath="$PREFIX/sbt-${SBT_VERSION}-$$"
        mkdir -p $tmppath
        url="https://piccolo.link/sbt-${SBT_VERSION}.tgz"
        echo "cd $tmppath; curl -L $url | tar xzf -"
        (
            cd $tmppath
            curl -L $url | tar xzf -
        )
        if [ ! -e "$PREFIX/sbt-${SBT_VERSION}/bin/sbt" ]; then
            if [ -e "$PREFIX/sbt-${SBT_VERSION}" ]; then
                rm -rf "$PREFIX/sbt-${SBT_VERSION}"
            fi
            echo mv $tmppath/sbt "$PREFIX/sbt-${SBT_VERSION}"
            mv $tmppath/sbt "$PREFIX/sbt-${SBT_VERSION}"
        fi
        rm -rf $tmppath
    fi

    export PATH="$PREFIX/sbt-${SBT_VERSION}/bin:$PATH"
}

################################################################################
# main
################################################################################

[ -v JDK_VERSION ] && install_jdk
[ -v SBT_VERSION ] && install_sbt

[ "$#" = 0 ] && usage

cmd="$1"; shift

if ! which "$cmd" >/dev/null; then
    echo "Not found: $cmd" >&2
    exit 1
fi

exec "$cmd" "$@"

################################################################################
