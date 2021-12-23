# MariaDB 10.2 Enterprise Install Log

The following is a capture of all the dependencies requirements that are installed on RHEL 7.9, this list might be different 
```
shell> yum -y install MariaDB-server MariaDB-backup
Loaded plugins: amazon-id, search-disabled-repos
epel/x86_64/metalink                                                                                                                                                                                                                                                   | 9.5 kB  00:00:00
epel                                                                                                                                                                                                                                                                   | 4.7 kB  00:00:00
mariadb-es-main                                                                                                                                                                                                                                                        | 3.3 kB  00:00:00
mariadb-maxscale                                                                                                                                                                                                                                                       | 2.5 kB  00:00:00
mariadb-tools                                                                                                                                                                                                                                                          | 2.9 kB  00:00:00
rhel-7-server-rhui-extras-rpms                                                                                                                                                                                                                                         | 2.0 kB  00:00:00
rhel-7-server-rhui-optional-rpms                                                                                                                                                                                                                                       | 1.8 kB  00:00:00
rhel-7-server-rhui-rh-common-rpms                                                                                                                                                                                                                                      | 2.1 kB  00:00:00
rhel-7-server-rhui-rpms                                                                                                                                                                                                                                                | 2.0 kB  00:00:00
rhui-client-config-server-7                                                                                                                                                                                                                                            | 2.1 kB  00:00:00
(1/22): epel/x86_64/group_gz                                                                                                                                                                                                                                           |  96 kB  00:00:00
(2/22): epel/x86_64/updateinfo                                                                                                                                                                                                                                         | 1.0 MB  00:00:00
(3/22): mariadb-tools/primary_db                                                                                                                                                                                                                                       |  17 kB  00:00:00
(4/22): epel/x86_64/primary_db                                                                                                                                                                                                                                         | 7.0 MB  00:00:00
(5/22): rhel-7-server-rhui-extras-rpms/x86_64/group                                                                                                                                                                                                                    |  124 B  00:00:00
(6/22): rhel-7-server-rhui-extras-rpms/x86_64/updateinfo                                                                                                                                                                                                               | 255 kB  00:00:00
(7/22): rhel-7-server-rhui-extras-rpms/x86_64/primary                                                                                                                                                                                                                  | 434 kB  00:00:00
(8/22): rhel-7-server-rhui-optional-rpms/7Server/x86_64/group                                                                                                                                                                                                          |  26 kB  00:00:00
(9/22): rhel-7-server-rhui-optional-rpms/7Server/x86_64/updateinfo                                                                                                                                                                                                     | 3.0 MB  00:00:00
(10/22): rhel-7-server-rhui-optional-rpms/7Server/x86_64/primary                                                                                                                                                                                                       | 6.5 MB  00:00:00
(11/22): rhel-7-server-rhui-rh-common-rpms/7Server/x86_64/group                                                                                                                                                                                                        |  124 B  00:00:00
(12/22): mariadb-maxscale/primary_db                                                                                                                                                                                                                                   | 7.1 kB  00:00:01
(13/22): rhel-7-server-rhui-rh-common-rpms/7Server/x86_64/updateinfo                                                                                                                                                                                                   |  35 kB  00:00:00
(14/22): rhel-7-server-rhui-rh-common-rpms/7Server/x86_64/primary                                                                                                                                                                                                      |  66 kB  00:00:00
(15/22): mariadb-es-main/primary_db                                                                                                                                                                                                                                    |  17 kB  00:00:01
(16/22): rhel-7-server-rhui-rpms/7Server/x86_64/updateinfo                                                                                                                                                                                                             | 4.2 MB  00:00:00
(17/22): mariadb-es-main/updateinfo                                                                                                                                                                                                                                    | 1.9 kB  00:00:01
(18/22): rhel-7-server-rhui-rpms/7Server/x86_64/group                                                                                                                                                                                                                  | 772 kB  00:00:00
(19/22): rhui-client-config-server-7/x86_64/group                                                                                                                                                                                                                      |  124 B  00:00:00
(20/22): rhui-client-config-server-7/x86_64/updateinfo                                                                                                                                                                                                                 |   92 B  00:00:00
(21/22): rhui-client-config-server-7/x86_64/primary                                                                                                                                                                                                                    | 3.0 kB  00:00:00
(22/22): rhel-7-server-rhui-rpms/7Server/x86_64/primary                                                                                                                                                                                                                |  54 MB  00:00:00
rhel-7-server-rhui-extras-rpms                                                                                                                                                                                                                                                      1413/1413
rhel-7-server-rhui-optional-rpms                                                                                                                                                                                                                                                  23205/23205
rhel-7-server-rhui-rh-common-rpms                                                                                                                                                                                                                                                     243/243
rhel-7-server-rhui-rpms                                                                                                                                                                                                                                                           32568/32568
rhui-client-config-server-7                                                                                                                                                                                                                                                             18/18
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-backup.x86_64 0:10.2.41_14-1.el7_9 will be installed
--> Processing Dependency: libaio.so.1(LIBAIO_0.1)(64bit) for package: MariaDB-backup-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: libaio.so.1(LIBAIO_0.4)(64bit) for package: MariaDB-backup-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: MariaDB-common for package: MariaDB-backup-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: libaio.so.1()(64bit) for package: MariaDB-backup-10.2.41_14-1.el7_9.x86_64
---> Package MariaDB-server.x86_64 0:10.2.41_14-1.el7_9 will be installed
--> Processing Dependency: perl(strict) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: MariaDB-client for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(POSIX) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(DBI) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(File::Basename) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(Sys::Hostname) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(File::Path) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(vars) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(Getopt::Long) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(Data::Dumper) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: /usr/bin/perl for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: lsof for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(File::Copy) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: galera-enterprise-3 for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Processing Dependency: perl(File::Temp) for package: MariaDB-server-10.2.41_14-1.el7_9.x86_64
--> Running transaction check
---> Package MariaDB-client.x86_64 0:10.2.41_14-1.el7_9 will be installed
--> Processing Dependency: perl(Exporter) for package: MariaDB-client-10.2.41_14-1.el7_9.x86_64
---> Package MariaDB-common.x86_64 0:10.2.41_14-1.el7_9 will be installed
--> Processing Dependency: MariaDB-compat for package: MariaDB-common-10.2.41_14-1.el7_9.x86_64
---> Package galera-enterprise-3.x86_64 0:25.3.35-1.el7_9 will be installed
--> Processing Dependency: socat for package: galera-enterprise-3-25.3.35-1.el7_9.x86_64
--> Processing Dependency: libboost_program_options-mt.so.1.53.0()(64bit) for package: galera-enterprise-3-25.3.35-1.el7_9.x86_64
---> Package libaio.x86_64 0:0.3.109-13.el7 will be installed
---> Package lsof.x86_64 0:4.87-6.el7 will be installed
---> Package perl.x86_64 4:5.16.3-299.el7_9 will be installed
--> Processing Dependency: perl-libs = 4:5.16.3-299.el7_9 for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Socket) >= 1.3 for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Scalar::Util) >= 1.10 for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl-macros for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl-libs for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(threads::shared) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(threads) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(constant) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Time::Local) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Time::HiRes) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Storable) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Socket) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Scalar::Util) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Pod::Simple::XHTML) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Pod::Simple::Search) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Filter::Util::Call) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Spec::Unix) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Spec::Functions) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(File::Spec) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Cwd) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: perl(Carp) for package: 4:perl-5.16.3-299.el7_9.x86_64
--> Processing Dependency: libperl.so()(64bit) for package: 4:perl-5.16.3-299.el7_9.x86_64
---> Package perl-DBI.x86_64 0:1.627-4.el7 will be installed
--> Processing Dependency: perl(RPC::PlServer) >= 0.2001 for package: perl-DBI-1.627-4.el7.x86_64
--> Processing Dependency: perl(RPC::PlClient) >= 0.2000 for package: perl-DBI-1.627-4.el7.x86_64
---> Package perl-Data-Dumper.x86_64 0:2.145-3.el7 will be installed
---> Package perl-File-Path.noarch 0:2.09-2.el7 will be installed
---> Package perl-File-Temp.noarch 0:0.23.01-3.el7 will be installed
---> Package perl-Getopt-Long.noarch 0:2.40-3.el7 will be installed
--> Processing Dependency: perl(Pod::Usage) >= 1.14 for package: perl-Getopt-Long-2.40-3.el7.noarch
--> Processing Dependency: perl(Text::ParseWords) for package: perl-Getopt-Long-2.40-3.el7.noarch
--> Running transaction check
---> Package MariaDB-compat.x86_64 0:10.2.41_14-1.el7_9 will be installed
---> Package boost-program-options.x86_64 0:1.53.0-28.el7 will be installed
---> Package perl-Carp.noarch 0:1.26-244.el7 will be installed
---> Package perl-Exporter.noarch 0:5.68-3.el7 will be installed
---> Package perl-Filter.x86_64 0:1.49-3.el7 will be installed
---> Package perl-PathTools.x86_64 0:3.40-5.el7 will be installed
---> Package perl-PlRPC.noarch 0:0.2020-14.el7 will be installed
--> Processing Dependency: perl(Net::Daemon) >= 0.13 for package: perl-PlRPC-0.2020-14.el7.noarch
--> Processing Dependency: perl(Net::Daemon::Test) for package: perl-PlRPC-0.2020-14.el7.noarch
--> Processing Dependency: perl(Net::Daemon::Log) for package: perl-PlRPC-0.2020-14.el7.noarch
--> Processing Dependency: perl(Compress::Zlib) for package: perl-PlRPC-0.2020-14.el7.noarch
---> Package perl-Pod-Simple.noarch 1:3.28-4.el7 will be installed
--> Processing Dependency: perl(Pod::Escapes) >= 1.04 for package: 1:perl-Pod-Simple-3.28-4.el7.noarch
--> Processing Dependency: perl(Encode) for package: 1:perl-Pod-Simple-3.28-4.el7.noarch
---> Package perl-Pod-Usage.noarch 0:1.63-3.el7 will be installed
--> Processing Dependency: perl(Pod::Text) >= 3.15 for package: perl-Pod-Usage-1.63-3.el7.noarch
--> Processing Dependency: perl-Pod-Perldoc for package: perl-Pod-Usage-1.63-3.el7.noarch
---> Package perl-Scalar-List-Utils.x86_64 0:1.27-248.el7 will be installed
---> Package perl-Socket.x86_64 0:2.010-5.el7 will be installed
---> Package perl-Storable.x86_64 0:2.45-3.el7 will be installed
---> Package perl-Text-ParseWords.noarch 0:3.29-4.el7 will be installed
---> Package perl-Time-HiRes.x86_64 4:1.9725-3.el7 will be installed
---> Package perl-Time-Local.noarch 0:1.2300-2.el7 will be installed
---> Package perl-constant.noarch 0:1.27-2.el7 will be installed
---> Package perl-libs.x86_64 4:5.16.3-299.el7_9 will be installed
---> Package perl-macros.x86_64 4:5.16.3-299.el7_9 will be installed
---> Package perl-threads.x86_64 0:1.87-4.el7 will be installed
---> Package perl-threads-shared.x86_64 0:1.43-6.el7 will be installed
---> Package socat.x86_64 0:1.7.3.2-2.el7 will be installed
--> Running transaction check
---> Package perl-Encode.x86_64 0:2.51-7.el7 will be installed
---> Package perl-IO-Compress.noarch 0:2.061-2.el7 will be installed
--> Processing Dependency: perl(Compress::Raw::Zlib) >= 2.061 for package: perl-IO-Compress-2.061-2.el7.noarch
--> Processing Dependency: perl(Compress::Raw::Bzip2) >= 2.061 for package: perl-IO-Compress-2.061-2.el7.noarch
---> Package perl-Net-Daemon.noarch 0:0.48-5.el7 will be installed
---> Package perl-Pod-Escapes.noarch 1:1.04-299.el7_9 will be installed
---> Package perl-Pod-Perldoc.noarch 0:3.20-4.el7 will be installed
--> Processing Dependency: perl(parent) for package: perl-Pod-Perldoc-3.20-4.el7.noarch
--> Processing Dependency: perl(HTTP::Tiny) for package: perl-Pod-Perldoc-3.20-4.el7.noarch
---> Package perl-podlators.noarch 0:2.5.1-3.el7 will be installed
--> Running transaction check
---> Package perl-Compress-Raw-Bzip2.x86_64 0:2.061-3.el7 will be installed
---> Package perl-Compress-Raw-Zlib.x86_64 1:2.061-4.el7 will be installed
---> Package perl-HTTP-Tiny.noarch 0:0.033-3.el7 will be installed
---> Package perl-parent.noarch 1:0.225-244.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================================================================================================================================================================================
 Package                                                                    Arch                                                      Version                                                                Repository                                                                  Size
==============================================================================================================================================================================================================================================================================================
Installing:
 MariaDB-backup                                                             x86_64                                                    10.2.41_14-1.el7_9                                                     mariadb-es-main                                                            5.9 M
 MariaDB-server                                                             x86_64                                                    10.2.41_14-1.el7_9                                                     mariadb-es-main                                                             19 M
Installing for dependencies:
 MariaDB-client                                                             x86_64                                                    10.2.41_14-1.el7_9                                                     mariadb-es-main                                                            6.1 M
 MariaDB-common                                                             x86_64                                                    10.2.41_14-1.el7_9                                                     mariadb-es-main                                                             82 k
 MariaDB-compat                                                             x86_64                                                    10.2.41_14-1.el7_9                                                     mariadb-es-main                                                            2.2 M
 boost-program-options                                                      x86_64                                                    1.53.0-28.el7                                                          rhel-7-server-rhui-rpms                                                    156 k
 galera-enterprise-3                                                        x86_64                                                    25.3.35-1.el7_9                                                        mariadb-es-main                                                            1.0 M
 libaio                                                                     x86_64                                                    0.3.109-13.el7                                                         rhel-7-server-rhui-rpms                                                     24 k
 lsof                                                                       x86_64                                                    4.87-6.el7                                                             rhel-7-server-rhui-rpms                                                    331 k
 perl                                                                       x86_64                                                    4:5.16.3-299.el7_9                                                     rhel-7-server-rhui-rpms                                                    8.0 M
 perl-Carp                                                                  noarch                                                    1.26-244.el7                                                           rhel-7-server-rhui-rpms                                                     19 k
 perl-Compress-Raw-Bzip2                                                    x86_64                                                    2.061-3.el7                                                            rhel-7-server-rhui-rpms                                                     32 k
 perl-Compress-Raw-Zlib                                                     x86_64                                                    1:2.061-4.el7                                                          rhel-7-server-rhui-rpms                                                     57 k
 perl-DBI                                                                   x86_64                                                    1.627-4.el7                                                            rhel-7-server-rhui-rpms                                                    802 k
 perl-Data-Dumper                                                           x86_64                                                    2.145-3.el7                                                            rhel-7-server-rhui-rpms                                                     47 k
 perl-Encode                                                                x86_64                                                    2.51-7.el7                                                             rhel-7-server-rhui-rpms                                                    1.5 M
 perl-Exporter                                                              noarch                                                    5.68-3.el7                                                             rhel-7-server-rhui-rpms                                                     28 k
 perl-File-Path                                                             noarch                                                    2.09-2.el7                                                             rhel-7-server-rhui-rpms                                                     27 k
 perl-File-Temp                                                             noarch                                                    0.23.01-3.el7                                                          rhel-7-server-rhui-rpms                                                     56 k
 perl-Filter                                                                x86_64                                                    1.49-3.el7                                                             rhel-7-server-rhui-rpms                                                     76 k
 perl-Getopt-Long                                                           noarch                                                    2.40-3.el7                                                             rhel-7-server-rhui-rpms                                                     56 k
 perl-HTTP-Tiny                                                             noarch                                                    0.033-3.el7                                                            rhel-7-server-rhui-rpms                                                     38 k
 perl-IO-Compress                                                           noarch                                                    2.061-2.el7                                                            rhel-7-server-rhui-rpms                                                    260 k
 perl-Net-Daemon                                                            noarch                                                    0.48-5.el7                                                             rhel-7-server-rhui-rpms                                                     51 k
 perl-PathTools                                                             x86_64                                                    3.40-5.el7                                                             rhel-7-server-rhui-rpms                                                     83 k
 perl-PlRPC                                                                 noarch                                                    0.2020-14.el7                                                          rhel-7-server-rhui-rpms                                                     36 k
 perl-Pod-Escapes                                                           noarch                                                    1:1.04-299.el7_9                                                       rhel-7-server-rhui-rpms                                                     52 k
 perl-Pod-Perldoc                                                           noarch                                                    3.20-4.el7                                                             rhel-7-server-rhui-rpms                                                     87 k
 perl-Pod-Simple                                                            noarch                                                    1:3.28-4.el7                                                           rhel-7-server-rhui-rpms                                                    216 k
 perl-Pod-Usage                                                             noarch                                                    1.63-3.el7                                                             rhel-7-server-rhui-rpms                                                     27 k
 perl-Scalar-List-Utils                                                     x86_64                                                    1.27-248.el7                                                           rhel-7-server-rhui-rpms                                                     36 k
 perl-Socket                                                                x86_64                                                    2.010-5.el7                                                            rhel-7-server-rhui-rpms                                                     49 k
 perl-Storable                                                              x86_64                                                    2.45-3.el7                                                             rhel-7-server-rhui-rpms                                                     77 k
 perl-Text-ParseWords                                                       noarch                                                    3.29-4.el7                                                             rhel-7-server-rhui-rpms                                                     14 k
 perl-Time-HiRes                                                            x86_64                                                    4:1.9725-3.el7                                                         rhel-7-server-rhui-rpms                                                     45 k
 perl-Time-Local                                                            noarch                                                    1.2300-2.el7                                                           rhel-7-server-rhui-rpms                                                     24 k
 perl-constant                                                              noarch                                                    1.27-2.el7                                                             rhel-7-server-rhui-rpms                                                     19 k
 perl-libs                                                                  x86_64                                                    4:5.16.3-299.el7_9                                                     rhel-7-server-rhui-rpms                                                    690 k
 perl-macros                                                                x86_64                                                    4:5.16.3-299.el7_9                                                     rhel-7-server-rhui-rpms                                                     44 k
 perl-parent                                                                noarch                                                    1:0.225-244.el7                                                        rhel-7-server-rhui-rpms                                                     12 k
 perl-podlators                                                             noarch                                                    2.5.1-3.el7                                                            rhel-7-server-rhui-rpms                                                    112 k
 perl-threads                                                               x86_64                                                    1.87-4.el7                                                             rhel-7-server-rhui-rpms                                                     49 k
 perl-threads-shared                                                        x86_64                                                    1.43-6.el7                                                             rhel-7-server-rhui-rpms                                                     39 k
 socat                                                                      x86_64                                                    1.7.3.2-2.el7                                                          rhel-7-server-rhui-rpms                                                    290 k

Transaction Summary
==============================================================================================================================================================================================================================================================================================
Install  2 Packages (+42 Dependent packages)

Total download size: 48 M
Installed size: 217 M
Downloading packages:
(1/44): MariaDB-backup-10.2.41_14-1.el7_9.x86_64.rpm                                                                                                                                                                                                                   | 5.9 MB  00:00:01
(2/44): MariaDB-client-10.2.41_14-1.el7_9.x86_64.rpm                                                                                                                                                                                                                   | 6.1 MB  00:00:02
(3/44): MariaDB-common-10.2.41_14-1.el7_9.x86_64.rpm                                                                                                                                                                                                                   |  82 kB  00:00:00
(4/44): MariaDB-compat-10.2.41_14-1.el7_9.x86_64.rpm                                                                                                                                                                                                                   | 2.2 MB  00:00:01
(5/44): boost-program-options-1.53.0-28.el7.x86_64.rpm                                                                                                                                                                                                                 | 156 kB  00:00:00
(6/44): lsof-4.87-6.el7.x86_64.rpm                                                                                                                                                                                                                                     | 331 kB  00:00:00
(7/44): libaio-0.3.109-13.el7.x86_64.rpm                                                                                                                                                                                                                               |  24 kB  00:00:00
(8/44): perl-5.16.3-299.el7_9.x86_64.rpm                                                                                                                                                                                                                               | 8.0 MB  00:00:00
(9/44): perl-Carp-1.26-244.el7.noarch.rpm                                                                                                                                                                                                                              |  19 kB  00:00:00
(10/44): perl-Compress-Raw-Bzip2-2.061-3.el7.x86_64.rpm                                                                                                                                                                                                                |  32 kB  00:00:00
(11/44): perl-Compress-Raw-Zlib-2.061-4.el7.x86_64.rpm                                                                                                                                                                                                                 |  57 kB  00:00:00
(12/44): perl-DBI-1.627-4.el7.x86_64.rpm                                                                                                                                                                                                                               | 802 kB  00:00:00
(13/44): perl-Data-Dumper-2.145-3.el7.x86_64.rpm                                                                                                                                                                                                                       |  47 kB  00:00:00
(14/44): perl-Encode-2.51-7.el7.x86_64.rpm                                                                                                                                                                                                                             | 1.5 MB  00:00:00
(15/44): perl-Exporter-5.68-3.el7.noarch.rpm                                                                                                                                                                                                                           |  28 kB  00:00:00
(16/44): perl-File-Path-2.09-2.el7.noarch.rpm                                                                                                                                                                                                                          |  27 kB  00:00:00
(17/44): perl-File-Temp-0.23.01-3.el7.noarch.rpm                                                                                                                                                                                                                       |  56 kB  00:00:00
(18/44): perl-Filter-1.49-3.el7.x86_64.rpm                                                                                                                                                                                                                             |  76 kB  00:00:00
(19/44): perl-Getopt-Long-2.40-3.el7.noarch.rpm                                                                                                                                                                                                                        |  56 kB  00:00:00
(20/44): perl-HTTP-Tiny-0.033-3.el7.noarch.rpm                                                                                                                                                                                                                         |  38 kB  00:00:00
(21/44): perl-IO-Compress-2.061-2.el7.noarch.rpm                                                                                                                                                                                                                       | 260 kB  00:00:00
(22/44): perl-Net-Daemon-0.48-5.el7.noarch.rpm                                                                                                                                                                                                                         |  51 kB  00:00:00
(23/44): perl-PathTools-3.40-5.el7.x86_64.rpm                                                                                                                                                                                                                          |  83 kB  00:00:00
(24/44): galera-enterprise-3-25.3.35-1.el7_9.x86_64.rpm                                                                                                                                                                                                                | 1.0 MB  00:00:01
(25/44): perl-PlRPC-0.2020-14.el7.noarch.rpm                                                                                                                                                                                                                           |  36 kB  00:00:00
(26/44): perl-Pod-Escapes-1.04-299.el7_9.noarch.rpm                                                                                                                                                                                                                    |  52 kB  00:00:00
(27/44): perl-Pod-Perldoc-3.20-4.el7.noarch.rpm                                                                                                                                                                                                                        |  87 kB  00:00:00
(28/44): perl-Pod-Simple-3.28-4.el7.noarch.rpm                                                                                                                                                                                                                         | 216 kB  00:00:00
(29/44): MariaDB-server-10.2.41_14-1.el7_9.x86_64.rpm                                                                                                                                                                                                                  |  19 MB  00:00:01
(30/44): perl-Pod-Usage-1.63-3.el7.noarch.rpm                                                                                                                                                                                                                          |  27 kB  00:00:00
(31/44): perl-Scalar-List-Utils-1.27-248.el7.x86_64.rpm                                                                                                                                                                                                                |  36 kB  00:00:00
(32/44): perl-Socket-2.010-5.el7.x86_64.rpm                                                                                                                                                                                                                            |  49 kB  00:00:00
(33/44): perl-Text-ParseWords-3.29-4.el7.noarch.rpm                                                                                                                                                                                                                    |  14 kB  00:00:00
(34/44): perl-Storable-2.45-3.el7.x86_64.rpm                                                                                                                                                                                                                           |  77 kB  00:00:00
(35/44): perl-Time-HiRes-1.9725-3.el7.x86_64.rpm                                                                                                                                                                                                                       |  45 kB  00:00:00
(36/44): perl-Time-Local-1.2300-2.el7.noarch.rpm                                                                                                                                                                                                                       |  24 kB  00:00:00
(37/44): perl-constant-1.27-2.el7.noarch.rpm                                                                                                                                                                                                                           |  19 kB  00:00:00
(38/44): perl-libs-5.16.3-299.el7_9.x86_64.rpm                                                                                                                                                                                                                         | 690 kB  00:00:00
(39/44): perl-macros-5.16.3-299.el7_9.x86_64.rpm                                                                                                                                                                                                                       |  44 kB  00:00:00
(40/44): perl-parent-0.225-244.el7.noarch.rpm                                                                                                                                                                                                                          |  12 kB  00:00:00
(41/44): perl-podlators-2.5.1-3.el7.noarch.rpm                                                                                                                                                                                                                         | 112 kB  00:00:00
(42/44): perl-threads-1.87-4.el7.x86_64.rpm                                                                                                                                                                                                                            |  49 kB  00:00:00
(43/44): perl-threads-shared-1.43-6.el7.x86_64.rpm                                                                                                                                                                                                                     |  39 kB  00:00:00
(44/44): socat-1.7.3.2-2.el7.x86_64.rpm                                                                                                                                                                                                                                | 290 kB  00:00:00
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                                         8.8 MB/s |  48 MB  00:00:05
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-compat-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                  1/44
  Installing : MariaDB-common-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                  2/44
  Installing : libaio-0.3.109-13.el7.x86_64                                                                                                                                                                                                                                              3/44
  Installing : lsof-4.87-6.el7.x86_64                                                                                                                                                                                                                                                    4/44
  Installing : 1:perl-parent-0.225-244.el7.noarch                                                                                                                                                                                                                                        5/44
  Installing : perl-HTTP-Tiny-0.033-3.el7.noarch                                                                                                                                                                                                                                         6/44
  Installing : perl-podlators-2.5.1-3.el7.noarch                                                                                                                                                                                                                                         7/44
  Installing : perl-Pod-Perldoc-3.20-4.el7.noarch                                                                                                                                                                                                                                        8/44
  Installing : 1:perl-Pod-Escapes-1.04-299.el7_9.noarch                                                                                                                                                                                                                                  9/44
  Installing : perl-Encode-2.51-7.el7.x86_64                                                                                                                                                                                                                                            10/44
  Installing : perl-Text-ParseWords-3.29-4.el7.noarch                                                                                                                                                                                                                                   11/44
  Installing : perl-Pod-Usage-1.63-3.el7.noarch                                                                                                                                                                                                                                         12/44
  Installing : 4:perl-macros-5.16.3-299.el7_9.x86_64                                                                                                                                                                                                                                    13/44
  Installing : 4:perl-Time-HiRes-1.9725-3.el7.x86_64                                                                                                                                                                                                                                    14/44
  Installing : perl-Exporter-5.68-3.el7.noarch                                                                                                                                                                                                                                          15/44
  Installing : perl-constant-1.27-2.el7.noarch                                                                                                                                                                                                                                          16/44
  Installing : perl-Socket-2.010-5.el7.x86_64                                                                                                                                                                                                                                           17/44
  Installing : perl-Time-Local-1.2300-2.el7.noarch                                                                                                                                                                                                                                      18/44
  Installing : perl-Carp-1.26-244.el7.noarch                                                                                                                                                                                                                                            19/44
  Installing : perl-Storable-2.45-3.el7.x86_64                                                                                                                                                                                                                                          20/44
  Installing : perl-PathTools-3.40-5.el7.x86_64                                                                                                                                                                                                                                         21/44
  Installing : perl-Scalar-List-Utils-1.27-248.el7.x86_64                                                                                                                                                                                                                               22/44
  Installing : 1:perl-Pod-Simple-3.28-4.el7.noarch                                                                                                                                                                                                                                      23/44
  Installing : perl-File-Temp-0.23.01-3.el7.noarch                                                                                                                                                                                                                                      24/44
  Installing : perl-File-Path-2.09-2.el7.noarch                                                                                                                                                                                                                                         25/44
  Installing : perl-threads-shared-1.43-6.el7.x86_64                                                                                                                                                                                                                                    26/44
  Installing : perl-threads-1.87-4.el7.x86_64                                                                                                                                                                                                                                           27/44
  Installing : perl-Filter-1.49-3.el7.x86_64                                                                                                                                                                                                                                            28/44
  Installing : 4:perl-libs-5.16.3-299.el7_9.x86_64                                                                                                                                                                                                                                      29/44
  Installing : perl-Getopt-Long-2.40-3.el7.noarch                                                                                                                                                                                                                                       30/44
  Installing : 4:perl-5.16.3-299.el7_9.x86_64                                                                                                                                                                                                                                           31/44
  Installing : perl-Data-Dumper-2.145-3.el7.x86_64                                                                                                                                                                                                                                      32/44
  Installing : perl-Net-Daemon-0.48-5.el7.noarch                                                                                                                                                                                                                                        33/44
  Installing : perl-Compress-Raw-Bzip2-2.061-3.el7.x86_64                                                                                                                                                                                                                               34/44
  Installing : 1:perl-Compress-Raw-Zlib-2.061-4.el7.x86_64                                                                                                                                                                                                                              35/44
  Installing : perl-IO-Compress-2.061-2.el7.noarch                                                                                                                                                                                                                                      36/44
  Installing : perl-PlRPC-0.2020-14.el7.noarch                                                                                                                                                                                                                                          37/44
  Installing : perl-DBI-1.627-4.el7.x86_64                                                                                                                                                                                                                                              38/44
  Installing : MariaDB-client-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 39/44
  Installing : socat-1.7.3.2-2.el7.x86_64                                                                                                                                                                                                                                               40/44
  Installing : boost-program-options-1.53.0-28.el7.x86_64                                                                                                                                                                                                                               41/44
  Installing : galera-enterprise-3-25.3.35-1.el7_9.x86_64                                                                                                                                                                                                                               42/44
  Installing : MariaDB-server-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 43/44
211223  7:46:04 server_audit: MariaDB Audit Plugin version 1.4.12 STARTED.
211223  7:46:04 server_audit: Query cache is enabled with the TABLE events. Some table reads can be veiled.211223  7:46:04 server_audit: STOPPED

See the MariaDB Knowledgebase at http://mariadb.com/kb for more instructions.

As a MariaDB Corporation subscription customer please contact us
via https://support.mariadb.com/ to report problems.
You also can get consultative guidance on questions specific to your deployment,
such as how to tune for performance, high availability, security audits, and code review.

You also find detailed documentation about how to use MariaDB Enterprise Server at https://mariadb.com/docs/.
The latest information about MariaDB Server is available at https://mariadb.com/kb/en/library/release-notes/.

  Installing : MariaDB-backup-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 44/44
  Verifying  : perl-HTTP-Tiny-0.033-3.el7.noarch                                                                                                                                                                                                                                         1/44
  Verifying  : boost-program-options-1.53.0-28.el7.x86_64                                                                                                                                                                                                                                2/44
  Verifying  : perl-threads-shared-1.43-6.el7.x86_64                                                                                                                                                                                                                                     3/44
  Verifying  : 4:perl-Time-HiRes-1.9725-3.el7.x86_64                                                                                                                                                                                                                                     4/44
  Verifying  : lsof-4.87-6.el7.x86_64                                                                                                                                                                                                                                                    5/44
  Verifying  : perl-Exporter-5.68-3.el7.noarch                                                                                                                                                                                                                                           6/44
  Verifying  : perl-constant-1.27-2.el7.noarch                                                                                                                                                                                                                                           7/44
  Verifying  : perl-PathTools-3.40-5.el7.x86_64                                                                                                                                                                                                                                          8/44
  Verifying  : 4:perl-macros-5.16.3-299.el7_9.x86_64                                                                                                                                                                                                                                     9/44
  Verifying  : MariaDB-backup-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 10/44
  Verifying  : perl-Socket-2.010-5.el7.x86_64                                                                                                                                                                                                                                           11/44
  Verifying  : perl-Net-Daemon-0.48-5.el7.noarch                                                                                                                                                                                                                                        12/44
  Verifying  : 1:perl-parent-0.225-244.el7.noarch                                                                                                                                                                                                                                       13/44
  Verifying  : perl-File-Temp-0.23.01-3.el7.noarch                                                                                                                                                                                                                                      14/44
  Verifying  : 1:perl-Pod-Simple-3.28-4.el7.noarch                                                                                                                                                                                                                                      15/44
  Verifying  : perl-Time-Local-1.2300-2.el7.noarch                                                                                                                                                                                                                                      16/44
  Verifying  : 1:perl-Pod-Escapes-1.04-299.el7_9.noarch                                                                                                                                                                                                                                 17/44
  Verifying  : perl-Pod-Perldoc-3.20-4.el7.noarch                                                                                                                                                                                                                                       18/44
  Verifying  : perl-DBI-1.627-4.el7.x86_64                                                                                                                                                                                                                                              19/44
  Verifying  : libaio-0.3.109-13.el7.x86_64                                                                                                                                                                                                                                             20/44
  Verifying  : perl-Carp-1.26-244.el7.noarch                                                                                                                                                                                                                                            21/44
  Verifying  : perl-Data-Dumper-2.145-3.el7.x86_64                                                                                                                                                                                                                                      22/44
  Verifying  : MariaDB-common-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 23/44
  Verifying  : perl-Compress-Raw-Bzip2-2.061-3.el7.x86_64                                                                                                                                                                                                                               24/44
  Verifying  : perl-Storable-2.45-3.el7.x86_64                                                                                                                                                                                                                                          25/44
  Verifying  : perl-Scalar-List-Utils-1.27-248.el7.x86_64                                                                                                                                                                                                                               26/44
  Verifying  : 1:perl-Compress-Raw-Zlib-2.061-4.el7.x86_64                                                                                                                                                                                                                              27/44
  Verifying  : MariaDB-server-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 28/44
  Verifying  : perl-IO-Compress-2.061-2.el7.noarch                                                                                                                                                                                                                                      29/44
  Verifying  : perl-Pod-Usage-1.63-3.el7.noarch                                                                                                                                                                                                                                         30/44
  Verifying  : perl-PlRPC-0.2020-14.el7.noarch                                                                                                                                                                                                                                          31/44
  Verifying  : perl-Encode-2.51-7.el7.x86_64                                                                                                                                                                                                                                            32/44
  Verifying  : perl-podlators-2.5.1-3.el7.noarch                                                                                                                                                                                                                                        33/44
  Verifying  : MariaDB-compat-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 34/44
  Verifying  : 4:perl-5.16.3-299.el7_9.x86_64                                                                                                                                                                                                                                           35/44
  Verifying  : perl-File-Path-2.09-2.el7.noarch                                                                                                                                                                                                                                         36/44
  Verifying  : perl-threads-1.87-4.el7.x86_64                                                                                                                                                                                                                                           37/44
  Verifying  : perl-Filter-1.49-3.el7.x86_64                                                                                                                                                                                                                                            38/44
  Verifying  : perl-Getopt-Long-2.40-3.el7.noarch                                                                                                                                                                                                                                       39/44
  Verifying  : perl-Text-ParseWords-3.29-4.el7.noarch                                                                                                                                                                                                                                   40/44
  Verifying  : galera-enterprise-3-25.3.35-1.el7_9.x86_64                                                                                                                                                                                                                               41/44
  Verifying  : MariaDB-client-10.2.41_14-1.el7_9.x86_64                                                                                                                                                                                                                                 42/44
  Verifying  : 4:perl-libs-5.16.3-299.el7_9.x86_64                                                                                                                                                                                                                                      43/44
  Verifying  : socat-1.7.3.2-2.el7.x86_64                                                                                                                                                                                                                                               44/44

Installed:
  MariaDB-backup.x86_64 0:10.2.41_14-1.el7_9                                                                                                    MariaDB-server.x86_64 0:10.2.41_14-1.el7_9

Dependency Installed:
  MariaDB-client.x86_64 0:10.2.41_14-1.el7_9      MariaDB-common.x86_64 0:10.2.41_14-1.el7_9      MariaDB-compat.x86_64 0:10.2.41_14-1.el7_9      boost-program-options.x86_64 0:1.53.0-28.el7      galera-enterprise-3.x86_64 0:25.3.35-1.el7_9      libaio.x86_64 0:0.3.109-13.el7
  lsof.x86_64 0:4.87-6.el7                        perl.x86_64 4:5.16.3-299.el7_9                  perl-Carp.noarch 0:1.26-244.el7                 perl-Compress-Raw-Bzip2.x86_64 0:2.061-3.el7      perl-Compress-Raw-Zlib.x86_64 1:2.061-4.el7       perl-DBI.x86_64 0:1.627-4.el7
  perl-Data-Dumper.x86_64 0:2.145-3.el7           perl-Encode.x86_64 0:2.51-7.el7                 perl-Exporter.noarch 0:5.68-3.el7               perl-File-Path.noarch 0:2.09-2.el7                perl-File-Temp.noarch 0:0.23.01-3.el7             perl-Filter.x86_64 0:1.49-3.el7
  perl-Getopt-Long.noarch 0:2.40-3.el7            perl-HTTP-Tiny.noarch 0:0.033-3.el7             perl-IO-Compress.noarch 0:2.061-2.el7           perl-Net-Daemon.noarch 0:0.48-5.el7               perl-PathTools.x86_64 0:3.40-5.el7                perl-PlRPC.noarch 0:0.2020-14.el7
  perl-Pod-Escapes.noarch 1:1.04-299.el7_9        perl-Pod-Perldoc.noarch 0:3.20-4.el7            perl-Pod-Simple.noarch 1:3.28-4.el7             perl-Pod-Usage.noarch 0:1.63-3.el7                perl-Scalar-List-Utils.x86_64 0:1.27-248.el7      perl-Socket.x86_64 0:2.010-5.el7
  perl-Storable.x86_64 0:2.45-3.el7               perl-Text-ParseWords.noarch 0:3.29-4.el7        perl-Time-HiRes.x86_64 4:1.9725-3.el7           perl-Time-Local.noarch 0:1.2300-2.el7             perl-constant.noarch 0:1.27-2.el7                 perl-libs.x86_64 4:5.16.3-299.el7_9
  perl-macros.x86_64 4:5.16.3-299.el7_9           perl-parent.noarch 1:0.225-244.el7              perl-podlators.noarch 0:2.5.1-3.el7             perl-threads.x86_64 0:1.87-4.el7                  perl-threads-shared.x86_64 0:1.43-6.el7           socat.x86_64 0:1.7.3.2-2.el7

Complete!
```

## The Installed MariaDB Packages

```
shell> rpm -qa | grep -i mariadb
MariaDB-compat-10.2.41_14-1.el7_9.x86_64
MariaDB-client-10.2.41_14-1.el7_9.x86_64
MariaDB-server-10.2.41_14-1.el7_9.x86_64
MariaDB-common-10.2.41_14-1.el7_9.x86_64
MariaDB-backup-10.2.41_14-1.el7_9.x86_64

shell> rpm -qa | grep -i galera
galera-enterprise-3-25.3.35-1.el7_9.x86_64
```

If the `tar` pacakge is downloaded from <https://www.mariadb.com/downloads> and extracted, the following RPM files can be found in the extracted directory.

```
[root@ip-172-31-21-7 mariadb-enterprise-10.2.41-14-rhel-7-x86_64-rpms]# ls -rlt
total 41768
-rw-rw-r--. 1 ec2-user ec2-user  6195972 Nov 30 00:56 MariaDB-backup-10.2.41_14-1.el7_9.x86_64.rpm
-rw-r--r--. 1 ec2-user ec2-user    23348 Nov 30 00:56 jemalloc-devel-3.6.0-1.el7.x86_64.rpm
-rw-r--r--. 1 ec2-user ec2-user   106584 Nov 30 00:56 jemalloc-3.6.0-1.el7.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user  1078312 Nov 30 00:56 galera-enterprise-3-25.3.35-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user     7740 Nov 30 00:56 MariaDB-cracklib-password-check-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user  2257980 Nov 30 00:56 MariaDB-compat-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user    83840 Nov 30 00:56 MariaDB-common-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user  6443572 Nov 30 00:56 MariaDB-client-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user  5373360 Nov 30 00:56 MariaDB-rocksdb-engine-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user    10548 Nov 30 00:56 MariaDB-gssapi-server-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user  1131852 Nov 30 00:56 MariaDB-devel-10.2.41_14-1.el7_9.x86_64.rpm
-rw-rw-r--. 1 ec2-user ec2-user 19901500 Nov 30 00:56 MariaDB-server-10.2.41_14-1.el7_9.x86_64.rpm
drwxrwxr-x. 2 ec2-user ec2-user       66 Nov 30 00:56 unsupported
-rw-rw-r--. 1 ec2-user ec2-user   115596 Nov 30 00:56 MariaDB-shared-10.2.41_14-1.el7_9.x86_64.rpm
-rwxrwxr-x. 1 ec2-user ec2-user     1057 Nov 30 00:56 setup_repository
drwxrwxr-x. 2 ec2-user ec2-user     4096 Nov 30 00:56 repodata
-rw-rw-r--. 1 ec2-user ec2-user     1793 Nov 30 00:56 README
```

We can now find out the dependencies list easily for each of the RPM files in the package using `rpm -qpR <rpm filename>`. Alternatively we can simply make use of the awesome `xargs` command to get the same done for all the RPM files in the folder.

```
[root@ip-172-31-21-7 mariadb-enterprise-10.2.41-14-rhel-7-x86_64-rpms]# ls *rpm | xargs rpm -qpR | sort -u
/bin/bash
/bin/sh
config(galera-enterprise-3) = 25.3.35-1.el7_9
coreutils
findutils
galera-enterprise-3
gawk
grep
iproute
jemalloc = 3.6.0-1.el7
ld-linux-x86-64.so.2()(64bit)
ld-linux-x86-64.so.2(GLIBC_2.3)(64bit)
libaio.so.1()(64bit)
libaio.so.1(LIBAIO_0.1)(64bit)
libaio.so.1(LIBAIO_0.4)(64bit)
libboost_program_options-mt.so.1.53.0()(64bit)
libcom_err.so.2()(64bit)
libcrack.so.2()(64bit)
libcrypto.so.10()(64bit)
libcrypto.so.10(libcrypto.so.10)(64bit)
libcrypto.so.10(OPENSSL_1.0.2)(64bit)
libcrypt.so.1()(64bit)
libcrypt.so.1(GLIBC_2.2.5)(64bit)
libc.so.6()(64bit)
libc.so.6(GLIBC_2.10)(64bit)
libc.so.6(GLIBC_2.11)(64bit)
libc.so.6(GLIBC_2.14)(64bit)
libc.so.6(GLIBC_2.15)(64bit)
libc.so.6(GLIBC_2.16)(64bit)
libc.so.6(GLIBC_2.17)(64bit)
libc.so.6(GLIBC_2.2.5)(64bit)
libc.so.6(GLIBC_2.3.2)(64bit)
libc.so.6(GLIBC_2.3.4)(64bit)
libc.so.6(GLIBC_2.3)(64bit)
libc.so.6(GLIBC_2.4)(64bit)
libc.so.6(GLIBC_2.6)(64bit)
libc.so.6(GLIBC_2.7)(64bit)
libc.so.6(GLIBC_2.8)(64bit)
libc.so.6(GLIBC_2.9)(64bit)
libdl.so.2()(64bit)
libdl.so.2(GLIBC_2.2.5)(64bit)
libgcc_s.so.1()(64bit)
libgcc_s.so.1(GCC_3.0)(64bit)
libgssapi_krb5.so.2()(64bit)
libgssapi_krb5.so.2(gssapi_krb5_2_MIT)(64bit)
libjemalloc.so.1()(64bit)
libk5crypto.so.3()(64bit)
libkrb5.so.3()(64bit)
libkrb5.so.3(krb5_3_MIT)(64bit)
libmariadb.so.3()(64bit)
libm.so.6()(64bit)
libm.so.6(GLIBC_2.2.5)(64bit)
libncurses.so.5()(64bit)
libnsl.so.1()(64bit)
libpam.so.0()(64bit)
libpam.so.0(LIBPAM_1.0)(64bit)
libpam.so.0(LIBPAM_EXTENSION_1.0)(64bit)
libpthread.so.0()(64bit)
libpthread.so.0(GLIBC_2.12)(64bit)
libpthread.so.0(GLIBC_2.2.5)(64bit)
libpthread.so.0(GLIBC_2.3.2)(64bit)
libpthread.so.0(GLIBC_2.3.4)(64bit)
librt.so.1()(64bit)
librt.so.1(GLIBC_2.2.5)(64bit)
librt.so.1(GLIBC_2.3.3)(64bit)
libsepol >= 2.5-10.el7
libsnappy.so.1()(64bit)
libssl.so.10()(64bit)
libssl.so.10(libssl.so.10)(64bit)
libstdc++.so.6()(64bit)
libstdc++.so.6(CXXABI_1.3.3)(64bit)
libstdc++.so.6(CXXABI_1.3.5)(64bit)
libstdc++.so.6(CXXABI_1.3)(64bit)
libstdc++.so.6(CXXABI_1.3.7)(64bit)
libstdc++.so.6(GLIBCXX_3.4.10)(64bit)
libstdc++.so.6(GLIBCXX_3.4.11)(64bit)
libstdc++.so.6(GLIBCXX_3.4.14)(64bit)
libstdc++.so.6(GLIBCXX_3.4.15)(64bit)
libstdc++.so.6(GLIBCXX_3.4.17)(64bit)
libstdc++.so.6(GLIBCXX_3.4.18)(64bit)
libstdc++.so.6(GLIBCXX_3.4.19)(64bit)
libstdc++.so.6(GLIBCXX_3.4)(64bit)
libstdc++.so.6(GLIBCXX_3.4.9)(64bit)
libsystemd.so.0()(64bit)
libsystemd.so.0(LIBSYSTEMD_209)(64bit)
libtinfo.so.5()(64bit)
libz.so.1()(64bit)
libz.so.1(ZLIB_1.2.0)(64bit)
lsof
MariaDB-client
MariaDB-common
MariaDB-compat
MariaDB-server
MariaDB-server = 10.2.41_14-1.el7_9
perl(Data::Dumper)
perl(DBI)
perl(Exporter)
perl(Fcntl)
perl(File::Basename)
perl(File::Copy)
perl(File::Path)
perl(File::Temp)
perl(Getopt::Long)
perl(IPC::Open3)
perl(POSIX)
perl(strict)
perl(Sys::Hostname)
perl(vars)
rpmlib(CompressedFileNames) <= 3.0.4-1
rpmlib(FileDigests) <= 4.6.0-1
rpmlib(PayloadFilesHavePrefix) <= 4.0-1
rpmlib(PayloadIsXz) <= 5.2-1
rsync
rtld(GNU_HASH)
/sbin/ldconfig
socat
tar
/usr/bin/env
/usr/bin/perl
/usr/bin/pkg-config
which
```

The list above contains all the packages/tools that are required by the server, some of these would alreay be in the installed os like `tar`, `which`, etc. but suggest to verify each and every one.

We have used the `sort -u` to get a unique list of dependencies and avoid duplicates from being listed because some of the dependenceis are shared by multiple RPM files.

Using the same approach, we can find the dependencies for MaxScale RPM, unlike MariaDB tar package, the MaxScale is just one RPM file hence a simple `rpm -qpR <maxscale rpm filename>`. 

MaxScale RPM can be downloaded from <https://mariadb.com/downloads/community/maxscale/>

### Thanks.
#### Faisal~