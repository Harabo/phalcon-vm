#!/usr/bin/env bash

npm_install() {
    # npm
    #
    # Make sure we have the latest npm version and the update checker module
    npm install -g npm
    npm install -g npm-check-updates

    # Grunt
    #
    # Install or Update Grunt based on current state.  Updates are direct
    # from NPM
    if [[ "$(grunt --version)" ]]; then
        echo "Updating Grunt CLI"
        npm update -g grunt-cli &>/dev/null
        npm update -g grunt-sass &>/dev/null
        npm update -g grunt-cssjanus &>/dev/null
        npm update -g grunt-rtlcss &>/dev/null
    else
        echo "Installing Grunt CLI"
        npm install -g grunt-cli &>/dev/null
        npm install -g grunt-sass &>/dev/null
        npm install -g grunt-cssjanus &>/dev/null
        npm install -g grunt-rtlcss &>/dev/null
    fi
}

xdebug_install() {
    # Xdebug
    #
    # The version of Xdebug 2.4.0 that is available for our Ubuntu installation
    # is not compatible with PHP 7.0. We instead retrieve the source package and
    # go through the manual installation steps.
    if [[ -f /usr/lib/php/20151012/xdebug.so ]]; then
        echo "Xdebug already installed"
    else
        echo "Installing Xdebug"
        # Download and extract Xdebug.
        curl -L -O --silent https://xdebug.org/files/xdebug-2.4.0.tgz
        tar -xf xdebug-2.4.0.tgz
        cd xdebug-2.4.0
        # Create a build environment for Xdebug based on our PHP configuration.
        phpize
        # Complete configuration of the Xdebug build.
        ./configure -q
        # Build the Xdebug module for use with PHP.
        make -s
        # Install the module.
        cp modules/xdebug.so /usr/lib/php/20151012/xdebug.so
        # Clean up.
        cd ..
        rm -rf xdebug-2.4.0*
        echo "Xdebug installed"
    fi
}

ack_install() {
    # ack-grep
    #
    # Install ack-grep directory from the version hosted at beyondgrep.com as the
    # PPAs are not available yet.
    if [[ -f /usr/bin/ack ]]; then
        echo "ack-grep already installed"
    else
        echo "Installing ack-grep as ack"
        curl -s http://beyondgrep.com/ack-2.14-single-file > "/usr/bin/ack" && chmod +x "/usr/bin/ack"
    fi
}

composer_install() {
    # COMPOSER
    #
    # Install Composer if it is not yet available.
    if [[ ! -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
        echo "Installing Composer..."
        curl -sS "https://getcomposer.org/installer" | php
        chmod +x "composer.phar"
        mv "composer.phar" "/usr/local/bin/composer"
    fi

    # Update both Composer and any global packages. Updates to Composer are direct from
    # the master branch on its GitHub repository.
    if [[ -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
        echo "Updating Composer..."
        COMPOSER_HOME=/usr/local/src/composer composer self-update
        COMPOSER_HOME=/usr/local/src/composer composer -q global config bin-dir /usr/local/bin
        COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update phpunit/phpunit:5.3.*
        COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update phalcon/devtools:2.0.*
        COMPOSER_HOME=/usr/local/src/composer composer global update --ignore-platform-reqs
        
        ln -s /usr/local/bin/phalcon.php /usr/bin/phalcon
    fi
}

graphviz_install() {
    # Graphviz
    #
    # Set up a symlink between the Graphviz path defined in the default Webgrind
    # config and actual path.
    echo "Adding graphviz symlink for Webgrind..."
    ln -sf "/usr/bin/dot" "/usr/local/bin/dot"
}

webgrind_install() {
    # Webgrind install (for viewing callgrind/cachegrind files produced by
    # xdebug profiler)
    if [[ ! -d "/srv/www/default/webgrind" ]]; then
        echo -e "\nDownloading webgrind, see https://github.com/michaelschiller/webgrind.git"
        git clone "https://github.com/michaelschiller/webgrind.git" "/srv/www/default/webgrind"
    else
        echo -e "\nUpdating webgrind..."
        cd /srv/www/default/webgrind
        git pull --rebase origin master
    fi
}

opcached_install() {
    # Checkout Opcache Status to provide a dashboard for viewing statistics
    # about PHP's built in opcache.
    if [[ ! -d "/srv/www/default/opcache-status" ]]; then
        echo -e "\nDownloading Opcache Status, see https://github.com/rlerdorf/opcache-status/"
        cd /srv/www/default
        git clone "https://github.com/rlerdorf/opcache-status.git" opcache-status
    else
        echo -e "\nUpdating Opcache Status"
        cd /srv/www/default/opcache-status
        git pull --rebase origin master
    fi
}

mailcatcher_install() {
    # Mailcatcher
    #
    # Installs mailcatcher using RVM. RVM allows us to install the
    # current version of ruby and all mailcatcher dependencies reliably.
    local pkg

    rvm_version="$(/usr/bin/env rvm --silent --version 2>&1 | grep 'rvm ' | cut -d " " -f 2)"
    if [[ -n "${rvm_version}" ]]; then
        pkg="RVM"
        space_count="$(( 20 - ${#pkg}))" #11
        pack_space_count="$(( 30 - ${#rvm_version}))"
        real_space="$(( ${space_count} + ${pack_space_count} + ${#rvm_version}))"
        printf " * $pkg %${real_space}.${#rvm_version}s ${rvm_version}\n"
    else
        # RVM key D39DC0E3
        # Signatures introduced in 1.26.0
        gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys D39DC0E3
        gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys BF04FF17

        printf " * RVM [not installed]\n Installing from source"
        sudo curl --silent -L "https://get.rvm.io" | sudo bash -s stable --ruby
        sudo source "/usr/local/rvm/scripts/rvm"
    fi

    mailcatcher_version="$(/usr/bin/env mailcatcher --version 2>&1 | grep 'mailcatcher ' | cut -d " " -f 2)"
    if [[ -n "${mailcatcher_version}" ]]; then
        pkg="Mailcatcher"
        space_count="$(( 20 - ${#pkg}))" #11
        pack_space_count="$(( 30 - ${#mailcatcher_version}))"
        real_space="$(( ${space_count} + ${pack_space_count} + ${#mailcatcher_version}))"
        printf " * $pkg %${real_space}.${#mailcatcher_version}s ${mailcatcher_version}\n"
    else
        echo " * Mailcatcher [not installed]"
        sudo /usr/bin/env rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
        sudo /usr/bin/env rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail
    fi

    if [[ -f "/etc/init/mailcatcher.conf" ]]; then
        echo " *" Mailcatcher upstart already configured.
    else
        cp "/srv/config/init/mailcatcher.conf"  "/etc/init/mailcatcher.conf"
        echo " * Copied /srv/config/init/mailcatcher.conf    to /etc/init/mailcatcher.conf"
    fi

    if [[ -f "/etc/php/7.0/mods-available/mailcatcher.ini" ]]; then
        echo " * Mailcatcher php7 fpm already configured."
    else
        cp "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.0/mods-available/mailcatcher.ini"
        echo " * Copied /srv/config/php-config/mailcatcher.ini to /etc/php/7.0/mods-available/mailcatcher.ini"
    fi
}

npm_install
xdebug_install
ack_install
composer_install
graphviz_install
webgrind_install
opcached_install
mailcatcher_install