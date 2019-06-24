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
    --graalvm=<VER>  インストールするGraalVMのバージョンを指定

JDK
ex) --jdk=11

sbt
https://www.scala-sbt.org/download.html
ex) --sbt=1.2.8

GraalVM
https://github.com/oracle/graal/releases
ex) --graalvm=19.0.2
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
        --graalvm=* )
            GRAALVM_VERSION="${1#*=}"
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
# JDK
################################################################################

install_jdk() {
    if [ -v GRAALVM_VERSION ]; then
        echo "cannot use both --jdk=* and --graalvm=* options" >&2
        exit 1
    fi

    if [ ! -x "$PREFIX/jdk-${JDK_VERSION}/bin/java" ]; then
        uname=$(uname)
        if [ "$uname" = "Darwin" ]; then
            os_name='osx'
        elif [ "$uname" = "Linux" ]; then
            os_name='linux'
        else
            echo "Unknown OS: $uname" >&2
            exit 1
        fi

        tmppath="$PREFIX/jdk-${JDK_VERSION}-$$"
        mkdir -p $tmppath
        url="https://download.java.net/java/ga/jdk${JDK_VERSION}/openjdk-${JDK_VERSION}_${os_name}-x64_bin.tar.gz"

        echo "cd $tmppath; curl -L $url | tar xzf -"
        (
            cd $tmppath
            curl -L $url | tar xzf -
        )
        if [ ! -e "$PREFIX/jdk-${JDK_VERSION}/bin/java" ]; then
            if [ -e "$PREFIX/jdk-${JDK_VERSION}" ]; then
                rm -rf "$PREFIX/jdk-${JDK_VERSION}"
            fi
            if [ $os_name = "osx" ]; then
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
# GraalVM
################################################################################

install_graalvm() {
    if [ -v JDK_VERSION ]; then
        echo "cannot use both --jdk=* and --graalvm=* options" >&2
        exit 1
    fi

    if [ ! -x "$PREFIX/graalvm-${GRAALVM_VERSION}/bin/java" ]; then
        uname=$(uname)
        if [ "$uname" = "Darwin" ]; then
            os_name='darwin'
        elif [ "$uname" = "Linux" ]; then
            os_name='linux'
        else
            echo "Unknown OS: $uname" >&2
            exit 1
        fi

        tmppath="$PREFIX/graalvm-${GRAALVM_VERSION}-$$"
        mkdir -p $tmppath
        url="https://github.com/oracle/graal/releases/download/vm-${GRAALVM_VERSION}/graalvm-ce-${os_name}-amd64-${GRAALVM_VERSION}.tar.gz"
        echo "cd $tmppath; curl -L $url | tar xzf -"
        (
            cd $tmppath
            curl -L $url | tar xzf -
            $tmppath/graalvm-ce-${GRAALVM_VERSION}/bin/gu install native-image
        )
        if [ ! -e "$PREFIX/graalvm-${GRAALVM_VERSION}/bin/java" ]; then
            if [ -e "$PREFIX/graalvm-${GRAALVM_VERSION}" ]; then
                rm -rf "$PREFIX/graalvm-${GRAALVM_VERSION}"
            fi

            mv $tmppath/graalvm-ce-${GRAALVM_VERSION} "$PREFIX/graalvm-${GRAALVM_VERSION}"
        fi
        rm -rf $tmppath
    fi

    export PATH="$PREFIX/graalvm-${GRAALVM_VERSION}/bin:$PATH"
}

################################################################################
# main
################################################################################

[ -v JDK_VERSION ] && install_jdk
[ -v SBT_VERSION ] && install_sbt
[ -v GRAALVM_VERSION ] && install_graalvm

[ "$#" = 0 ] && usage

cmd="$1"; shift

if ! which "$cmd" >/dev/null; then
    echo "Not found: $cmd" >&2
    exit 1
fi

exec "$cmd" "$@"

################################################################################
