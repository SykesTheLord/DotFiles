import os
import subprocess


def is_ubuntu_or_neon():
    try:
        distro = (
            subprocess.check_output(["lsb_release", "-is"], stderr=subprocess.DEVNULL)
            .decode()
            .strip()
        )
        return distro in ["Ubuntu", "Neon"]
    except subprocess.CalledProcessError:
        return False


def is_debian():
    try:
        distro = (
            subprocess.check_output(["lsb_release", "-is"], stderr=subprocess.DEVNULL)
            .decode()
            .strip()
        )
        return distro == "Debian"
    except subprocess.CalledProcessError:
        return False


def is_arch_linux():
    return os.path.isfile("/etc/arch-release")


def is_fedora():
    return os.path.isfile("/etc/fedora-release")


def is_opensuse():
    try:
        with open("/etc/os-release", "r") as file:
            content = file.read()
            return "opensuse" in content.lower()
    except FileNotFoundError:
        return False


def list_files_recursive(path=".", files=[], directories=[]):
    to_remove = ""
    if is_arch_linux():
        to_remove = "./arch/"
    elif is_fedora():
        to_remove = "./fedora/"
    elif is_opensuse():
        to_remove = "./opensuse/"
    elif is_debian():
        to_remove = "./debian/"
    elif is_ubuntu_or_neon():
        to_remove = "./ubuntu/"
    directories_to_ignore = [".config", ".oh-my-zsh/themes", ".oh-my-zsh"]
    directory_files_to_ignore = [".themes",".icons",".oh-my-zsh/.github",".oh-my-zsh/.devcontainer",".oh-my-zsh/lib/",".oh-my-zsh/plugins",".oh-my-zsh/templates",".oh-my-zsh/tools", ".scripts"]
    files_to_ignore = [".oh-my-zsh/.editorconfig",
        ".oh-my-zsh/.gitignore",
        ".oh-my-zsh/.gitpod.Dockerfile",
        ".oh-my-zsh/.gitpod.yml",
        ".oh-my-zsh/.prettierrc",
        ".oh-my-zsh/CODE_OF_CONDUCT.md",
        ".oh-my-zsh/CONTRIBUTING.md",
        ".oh-my-zsh/LICENSE.txt",
        ".oh-my-zsh/README.md",
        ".oh-my-zsh/SECURITY.md",
        ".oh-my-zsh/oh-my-zsh.sh",
        ".oh-my-zsh/themes/3den.zsh-theme",
        ".oh-my-zsh/themes/Soliah.zsh-theme",
        ".oh-my-zsh/themes/adben.zsh-theme",
        ".oh-my-zsh/themes/af-magic.zsh-theme",
        ".oh-my-zsh/themes/afowler.zsh-theme",
        ".oh-my-zsh/themes/agnoster.zsh-theme",
        ".oh-my-zsh/themes/alanpeabody.zsh-theme",
        ".oh-my-zsh/themes/amuse.zsh-theme",
        ".oh-my-zsh/themes/apple.zsh-theme",
        ".oh-my-zsh/themes/arrow.zsh-theme",
        ".oh-my-zsh/themes/aussiegeek.zsh-theme",
        ".oh-my-zsh/themes/avit.zsh-theme",
        ".oh-my-zsh/themes/awesomepanda.zsh-theme",
        ".oh-my-zsh/themes/bira.zsh-theme",
        ".oh-my-zsh/themes/blinks.zsh-theme",
        ".oh-my-zsh/themes/bureau.zsh-theme",
        ".oh-my-zsh/themes/candy-kingdom.zsh-theme",
        ".oh-my-zsh/themes/candy.zsh-theme",
        ".oh-my-zsh/themes/clean.zsh-theme",
        ".oh-my-zsh/themes/cloud.zsh-theme",
        ".oh-my-zsh/themes/crcandy.zsh-theme",
        ".oh-my-zsh/themes/crunch.zsh-theme",
        ".oh-my-zsh/themes/cypher.zsh-theme",
        ".oh-my-zsh/themes/dallas.zsh-theme",
        ".oh-my-zsh/themes/darkblood.zsh-theme",
        ".oh-my-zsh/themes/daveverwer.zsh-theme",
        ".oh-my-zsh/themes/dieter.zsh-theme",
        ".oh-my-zsh/themes/dogenpunk.zsh-theme",
        ".oh-my-zsh/themes/dpoggi.zsh-theme",
        ".oh-my-zsh/themes/dst.zsh-theme",
        ".oh-my-zsh/themes/dstufft.zsh-theme",
        ".oh-my-zsh/themes/duellj.zsh-theme",
        ".oh-my-zsh/themes/eastwood.zsh-theme",
        ".oh-my-zsh/themes/edvardm.zsh-theme",
        ".oh-my-zsh/themes/emotty.zsh-theme",
        ".oh-my-zsh/themes/essembeh.zsh-theme",
        ".oh-my-zsh/themes/evan.zsh-theme",
        ".oh-my-zsh/themes/fino-time.zsh-theme",
        ".oh-my-zsh/themes/fino.zsh-theme",
        ".oh-my-zsh/themes/fishy.zsh-theme",
        ".oh-my-zsh/themes/flazz.zsh-theme",
        ".oh-my-zsh/themes/fletcherm.zsh-theme",
        ".oh-my-zsh/themes/fox.zsh-theme",
        ".oh-my-zsh/themes/frisk.zsh-theme",
        ".oh-my-zsh/themes/frontcube.zsh-theme",
        ".oh-my-zsh/themes/funky.zsh-theme",
        ".oh-my-zsh/themes/fwalch.zsh-theme",
        ".oh-my-zsh/themes/gallifrey.zsh-theme",
        ".oh-my-zsh/themes/gallois.zsh-theme",
        ".oh-my-zsh/themes/garyblessington.zsh-theme",
        ".oh-my-zsh/themes/gentoo.zsh-theme",
        ".oh-my-zsh/themes/geoffgarside.zsh-theme",
        ".oh-my-zsh/themes/gianu.zsh-theme",
        ".oh-my-zsh/themes/gnzh.zsh-theme",
        ".oh-my-zsh/themes/gozilla.zsh-theme",
        ".oh-my-zsh/themes/half-life.zsh-theme",
        ".oh-my-zsh/themes/humza.zsh-theme",
        ".oh-my-zsh/themes/imajes.zsh-theme",
        ".oh-my-zsh/themes/intheloop.zsh-theme",
        ".oh-my-zsh/themes/itchy.zsh-theme",
        ".oh-my-zsh/themes/jaischeema.zsh-theme",
        ".oh-my-zsh/themes/jbergantine.zsh-theme",
        ".oh-my-zsh/themes/jispwoso.zsh-theme",
        ".oh-my-zsh/themes/jnrowe.zsh-theme",
        ".oh-my-zsh/themes/jonathan.zsh-theme",
        ".oh-my-zsh/themes/josh.zsh-theme",
        ".oh-my-zsh/themes/jreese.zsh-theme",
        ".oh-my-zsh/themes/jtriley.zsh-theme",
        ".oh-my-zsh/themes/juanghurtado.zsh-theme",
        ".oh-my-zsh/themes/junkfood.zsh-theme",
        ".oh-my-zsh/themes/kafeitu.zsh-theme",
        ".oh-my-zsh/themes/kardan.zsh-theme",
        ".oh-my-zsh/themes/kennethreitz.zsh-theme",
        ".oh-my-zsh/themes/kiwi.zsh-theme",
        ".oh-my-zsh/themes/kolo.zsh-theme",
        ".oh-my-zsh/themes/kphoen.zsh-theme",
        ".oh-my-zsh/themes/lambda.zsh-theme",
        ".oh-my-zsh/themes/linuxonly.zsh-theme",
        ".oh-my-zsh/themes/lukerandall.zsh-theme",
        ".oh-my-zsh/themes/macovsky-ruby.zsh-theme",
        ".oh-my-zsh/themes/macovsky.zsh-theme",
        ".oh-my-zsh/themes/maran.zsh-theme",
        ".oh-my-zsh/themes/mgutz.zsh-theme",
        ".oh-my-zsh/themes/mh.zsh-theme",
        ".oh-my-zsh/themes/michelebologna.zsh-theme",
        ".oh-my-zsh/themes/mikeh.zsh-theme",
        ".oh-my-zsh/themes/miloshadzic.zsh-theme",
        ".oh-my-zsh/themes/minimal.zsh-theme",
        ".oh-my-zsh/themes/mira.zsh-theme",
        ".oh-my-zsh/themes/mlh.zsh-theme",
        ".oh-my-zsh/themes/mortalscumbag.zsh-theme",
        ".oh-my-zsh/themes/mrtazz.zsh-theme",
        ".oh-my-zsh/themes/murilasso.zsh-theme",
        ".oh-my-zsh/themes/muse.zsh-theme",
        ".oh-my-zsh/themes/nanotech.zsh-theme",
        ".oh-my-zsh/themes/nebirhos.zsh-theme",
        ".oh-my-zsh/themes/nicoulaj.zsh-theme",
        ".oh-my-zsh/themes/norm.zsh-theme",
        ".oh-my-zsh/themes/obraun.zsh-theme",
        ".oh-my-zsh/themes/oldgallois.zsh-theme",
        ".oh-my-zsh/themes/peepcode.zsh-theme",
        ".oh-my-zsh/themes/philips.zsh-theme",
        ".oh-my-zsh/themes/pmcgee.zsh-theme",
        ".oh-my-zsh/themes/pygmalion-virtualenv.zsh-theme",
        ".oh-my-zsh/themes/pygmalion.zsh-theme",
        ".oh-my-zsh/themes/random.zsh-theme",
        ".oh-my-zsh/themes/re5et.zsh-theme",
        ".oh-my-zsh/themes/refined.zsh-theme",
        ".oh-my-zsh/themes/rgm.zsh-theme",
        ".oh-my-zsh/themes/risto.zsh-theme",
        ".oh-my-zsh/themes/rixius.zsh-theme",
        ".oh-my-zsh/themes/rkj-repos.zsh-theme",
        ".oh-my-zsh/themes/rkj.zsh-theme",
        ".oh-my-zsh/themes/robbyrussell.zsh-theme",
        ".oh-my-zsh/themes/sammy.zsh-theme",
        ".oh-my-zsh/themes/simonoff.zsh-theme",
        ".oh-my-zsh/themes/simple.zsh-theme",
        ".oh-my-zsh/themes/skaro.zsh-theme",
        ".oh-my-zsh/themes/smt.zsh-theme",
        ".oh-my-zsh/themes/sonicradish.zsh-theme",
        ".oh-my-zsh/themes/sorin.zsh-theme",
        ".oh-my-zsh/themes/sporty_256.zsh-theme",
        ".oh-my-zsh/themes/steeef.zsh-theme",
        ".oh-my-zsh/themes/strug.zsh-theme",
        ".oh-my-zsh/themes/sunaku.zsh-theme",
        ".oh-my-zsh/themes/sunrise.zsh-theme",
        ".oh-my-zsh/themes/superjarin.zsh-theme",
        ".oh-my-zsh/themes/suvash.zsh-theme",
        ".oh-my-zsh/themes/takashiyoshida.zsh-theme",
        ".oh-my-zsh/themes/terminalparty.zsh-theme",
        ".oh-my-zsh/themes/theunraveler.zsh-theme",
        ".oh-my-zsh/themes/tjkirch.zsh-theme",
        ".oh-my-zsh/themes/tjkirch_mod.zsh-theme",
        ".oh-my-zsh/themes/tonotdo.zsh-theme",
        ".oh-my-zsh/themes/trapd00r.zsh-theme",
        ".oh-my-zsh/themes/wedisagree.zsh-theme",
        ".oh-my-zsh/themes/wezm+.zsh-theme",
        ".oh-my-zsh/themes/wezm.zsh-theme",
        ".oh-my-zsh/themes/wuffers.zsh-theme",
        ".oh-my-zsh/themes/xiong-chiamiov-plus.zsh-theme",
        ".oh-my-zsh/themes/xiong-chiamiov.zsh-theme",
        ".oh-my-zsh/themes/ys.zsh-theme",
        ".oh-my-zsh/themes/zhann.zsh-theme"]
    for entry in os.listdir(path):
        full_path = os.path.join(path, entry)
        if os.path.isdir(full_path):
            to_be_ignored = False
            for directory in directories_to_ignore:
                if full_path.replace(to_remove,"") == directory:
                    to_be_ignored = True
            for directory in directories:
                if full_path.startswith(directory):
                    to_be_ignored = True
            if to_be_ignored == False:
                directories.append(full_path)
            files, directories = list_files_recursive(full_path, files, directories)
        else:
            to_be_ignored = False
            for directory in directory_files_to_ignore:
                if full_path.replace(to_remove,"").startswith(directory):
                    to_be_ignored = True
            for directory in directories:
                if full_path.startswith(directory):
                    to_be_ignored = True
            for file in files_to_ignore:
                if full_path.replace(to_remove,"").startswith(file):
                    to_be_ignored = True
            if to_be_ignored == False:
                files.append(full_path)
    return files, directories


if is_arch_linux():
    print("Updating Arch files")
    directory_path = "./arch/"
    files_tmp, directories_tmp = list_files_recursive(directory_path)
    directories = []
    files = []
    for directory in directories_tmp:
        directories.append(directory.replace(directory_path, ""))
    for file in files_tmp:
        files.append(file.replace(directory_path, ""))
    for directory in directories:
        if directory.startswith(".config"):
            command = "cp -a ~/" + directory + " " + directory_path + ".config/"
        else:
            command = "cp -a ~/" + directory + " " + directory_path
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
    for file in files:
        command = "cp -a ~/" + file + " " + directory_path + file
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
elif is_fedora():
    print("Updating Fedora files")
    directory_path = "./fedora/"
    files_tmp, directories_tmp = list_files_recursive(directory_path)
    directories = []
    files = []
    for directory in directories_tmp:
        directories.append(directory.replace(directory_path, ""))
    for file in files_tmp:
        files.append(file.replace(directory_path, ""))
    for directory in directories:
        if directory.startswith(".config"):
            command = "cp -a ~/" + directory + " " + directory_path + ".config/"
        else:
            command = "cp -a ~/" + directory + " " + directory_path
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
    for file in files:
        command = "cp -a ~/" + file + " " + directory_path + file
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
elif is_opensuse():
    print("Updating openSuse files")
    directory_path = "./opensuse/"
    files_tmp, directories_tmp = list_files_recursive(directory_path)
    directories = []
    files = []
    for directory in directories_tmp:
        directories.append(directory.replace(directory_path, ""))
    for file in files_tmp:
        files.append(file.replace(directory_path, ""))
    for directory in directories:
        if directory.startswith(".config"):
            command = "cp -a ~/" + directory + " " + directory_path + ".config/"
        else:
            command = "cp -a ~/" + directory + " " + directory_path
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
    for file in files:
        command = "cp -a ~/" + file + " " + directory_path + file
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
elif is_debian():
    print("Updating Debian files")
    directory_path = "./debian/"
    files_tmp, directories_tmp = list_files_recursive(directory_path)
    directories = []
    files = []
    for directory in directories_tmp:
        directories.append(directory.replace(directory_path, ""))
    for file in files_tmp:
        files.append(file.replace(directory_path, ""))
    for directory in directories:
        if directory.startswith(".config"):
            command = "cp -a ~/" + directory + " " + directory_path + ".config/"
        else:
            command = "cp -a ~/" + directory + " " + directory_path
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
    for file in files:
        command = "cp -a ~/" + file + " " + directory_path + file
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
elif is_ubuntu_or_neon():
    print("Updating Ubuntu based files")
    directory_path = "./ubuntu/"
    files_tmp, directories_tmp = list_files_recursive(directory_path)
    directories = []
    files = []
    for directory in directories_tmp:
        directories.append(directory.replace(directory_path, ""))
    for file in files_tmp:
        files.append(file.replace(directory_path, ""))
    for directory in directories:
        if directory.startswith(".config"):
            command = "cp -a ~/" + directory + " " + directory_path + ".config/"
        else:
            command = "cp -a ~/" + directory + " " + directory_path
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
    for file in files:
        command = "cp -a ~/" + file + " " + directory_path + file
        print(command)
        os.system("/bin/bash -c \"" + command + "\"")
else:
    print("No supported distro in use.")
