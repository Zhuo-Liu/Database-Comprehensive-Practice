create database cbooo;

create table cinema
(
  cinema_id    int       not null,
  cinema_name  char(100) not null,
  amount       double    not null,
  avg_per_show double    not null,
  avg_screen   double    not null,
  screen_yield double    not null,
  scenes_time  double    not null,
  constraint cinema_cinema_id_uindex
    unique (cinema_id)
);

alter table cinema
  add primary key (cinema_id);

