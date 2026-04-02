TEMPLATE = aux

INSTALLER = installer

INPUT = $$PWD/config/config.xml $$PWD/packages
example.input = INPUT
example.output = $$INSTALLER
example.commands = binarycreator -c $$PWD/config/config.xml -p $$PWD/packages ${QMAKE_FILE_OUT}
example.CONFIG += target_predeps no_link combine

QMAKE_EXTRA_COMPILERS += example

OTHER_FILES = README



FORMS += \
    packages/com.ktsinfotech.infomateplayer/meta/additionalinstancewidget.ui

DISTFILES += \
    config/license.txt \
    packages/com.ktsinfotech.infomateplayer/data/TestProj.exe \
    packages/com.ktsinfotech.infomateplayer/meta/installscript.qs \
    packages/com.ktsinfotech.infomateplayer/meta/license.txt \
    packages/com.ktsinfotech.infomateplayer/meta/package.xml
