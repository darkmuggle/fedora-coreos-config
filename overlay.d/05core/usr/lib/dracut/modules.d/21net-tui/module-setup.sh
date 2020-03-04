#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    echo bash systemd network
}

install_unit() {
    local unit="$1"; shift
    local target="${1:-net-tui.target.requires}"; shift
    local instantiated="${1:-$unit}"; shift
    if [ -f "$moddir/$unit" ]; then
        inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    fi
    mkdir -p "$initdir/$systemdsystemunitdir/$target"
    ln_r -sf "../${unit}" "$instantiated"
}


install() {
    inst_multiple -o \
        ip \
        nmtui \
        find \
        teamd teamdctl

    # required libraries
    inst_libdir_file 'libslang*'
    inst_libdir_file 'libnewt*'

    # yeah...no beuno
    # The nmtui requires dbus.
    inst_multiple -o \
        busctl \
        dbus-broker \
        dbus-broker-launch \
        /usr/lib/systemd/system/dbus.socket \
        /usr/sbin/NetworkManager \
        $systemdsystemunitdir/dbus-org.freedesktop.nm-dispatcher.service \
        $systemdsystemunitdir/NetworkManager.service \
        $systemdsystemunitdir/dbus-broker.service \
        $systemdsystemunitdir/dbus.socket \
        /usr/libexec/nm-dhcp-helper \
        /usr/libexec/nm-dispatcher \
        /usr/libexec/nm-iface-helper \
        /usr/libexec/nm-ifdown \
        /usr/libexec/nm-ifup

    # Copy in dbus policies and NetworkManager supporting libs
    for x in /usr/lib/sysusers.d /usr/share/dbus-1 /usr/lib*/NetworkManager ; do
        for d in $(find $x -type d); do
            inst_dir $d
            inst_multiple -o $d/*
        done
    done

    inst_simple "$moddir/net-tui.target" "$systemdsystemunitdir/net-tui.target"
    install_unit dbus.socket            socket.target.wants
    install_unit coreos-nm.service
    install_unit coreos-net-tui.service

    inst_simple "$moddir/tui-generator" \
        "$systemdutildir/system-generators/tui-generator"
}
