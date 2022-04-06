# vps-centos7
Para otimizar o processo de configuração de uma vps com centos7 criei esses script para realizar a configuração com alguns detalhes:

-Web server : nginx;
-PHP-FPM;
-php 7.3;
-pool do php com nome persinalizado ouvindo em  /var/run/php-fpm/nomedapool.sock;
-Pool com processos por demanda;
-Script de backup que roda todo dia as 23:00h e remove os backups com mais de  7 dias.
