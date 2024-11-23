#include <sqlca.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define SUCCESS 0
#define AUTH_EXCEPTION 1

exec SQL begin declare section;
char db_name[50];
char user_name[10];
char user_password[10];


unsigned int count=0;


exec SQL end declare section;

void print_menu()
{
   printf("\n --------------Меню--------------\n");
   printf("\n 1 - Выполнить запрос №1 \n");
   printf("\n 2 - Выполнить запрос №2 \n");
   printf("\n 3 - Выполнить запрос №3 \n");
   printf("\n 4 - Выполнить запрос №4 \n");
   printf("\n 5 - Выполнить запрос №5 \n");
   printf("\n 0 - Выход \n");
}

void close_program()
{
   exec SQL DISCONNECT CURRENT;
   printf("Отключено от базы данных\n");
   exit(SUCCESS);
}

void print_table();
void task1();
void task2();
void task3();
void task4();
void task5();


int main()
{
   strcpy(db_name, "students");
   strcpy(user_name, "pmi-b1605");
   strcpy(user_password, "Kit5olya5");
   printf("Подключение к базе данных...\n");
   
   //Подключение к базе данных
   exec SQL CONNECT TO :db_name USER :user_name using :user_password;
   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка аутентификации. \n");
      exit(1);
   }
   else
   {
      printf("Подключено к базе данных \"students\" под пользователем %s \n", user_name);
   }

   exec SQL SET search_path TO pmib1605, public;

   int cmd = 1;

   print_menu();
   while (cmd != 0)
   {
      printf("Введите команду: ");
      scanf("%d", &cmd);
      switch (cmd) {
      case 1:
         task1();
         printf("\n 6 - Вывести все меню \n");
         break;
      case 2:
         task2();
         printf("\n 6 - Вывести все меню \n");
         break;
      case 3:
         task3();
         printf("\n 6 - Вывести все меню \n");
         break;
      case 4:
         task4();
         printf("\n 6 - Вывести все меню \n");
         break;
      case 5:
         task5();
         printf("\n 6 - Вывести все меню\n");
         break;
      case 6:
         print_menu();
         break;
      case 0:
         close_program();
         break;
      default:
         printf("Некорректная программа \n");
         printf("\n 6 - Вывести все меню \n");
      }
   }
   return 0;
}

void print_table()
{
   EXEC SQL BEGIN DECLARE SECTION;
   char n_izd[6];
   char name[40];
   char town[40];
   EXEC SQL END DECLARE SECTION;
   exec SQL declare curs4 CURSOR for
      Select j.*
      from j;
   if (sqlca.sqlcode < 0)
    {
      printf("Ошибка объявления курсора. Код: %d %s \n Текст ошибки: %s\n ",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL rollback;
      return;
   }
   printf("\nОткрытие курсора...\n");
   exec SQL begin;
   exec SQL OPEN curs4;
   if (sqlca.sqlcode < 0)
   {
       printf("Ошибка открытия курсора. Код: %d %s \n Текст ошибки: %s\n ",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL close curs4;  
      exec SQL rollback;
      return;
   }
   int row_count = 0;
   while (1)
   {
      exec SQL FETCH curs4 INTO :n_izd, :name, :town;
      if (sqlca.sqlcode < 0) {
         printf("Ошибка получения строки! Код: %d (%s)\n Текст ошибки: %s\n",
            sqlca.sqlcode,
            sqlca.sqlstate,
            sqlca.sqlerrm.sqlerrmc);
         exec SQL close curs4;
         exec SQL rollback;
         return;
      }
      if (sqlca.sqlcode == 100) break;
      if (row_count == 0) printf("n_izd\tname\t\ttown\n");
      printf("%s\t%s\t%s\n", n_izd, name, town);
      row_count++;
   }
   printf("Закрытие курсора...\n\n");
   exec SQL close curs4;
   exec SQL commit;
   if(row_count==0){
      printf("Нет данных.\n");
   }
   printf("Результат: %d строк(-а/и).\n", row_count);
   return;
}


void task1()
{
   printf("\n Текст запроса: \n");
   printf("1.Выдать число поставок, выполненных для изделий с деталями зеленого цвета.\n\n");
   printf("Выполнение запроса...\n");
   exec SQL begin;
   exec SQL
      SELECT COUNT(*) INTO:count
      FROM spj
      WHERE spj.n_izd IN(SELECT spj.n_izd
                        FROM spj
                        WHERE spj.n_det IN(SELECT p.n_det
                                          FROM p
                                          WHERE p.cvet = 'Зеленый'
                                          )
 
                        );


   if (sqlca.sqlcode < 0) {
      printf("Ошибка запроса select! Код: %d %s \n Текст ошибки: %s\n ", sqlca.sqlcode, sqlca.sqlstate, sqlca.sqlerrm.sqlerrmc);
      exec SQL rollback;
      return;
   }
   printf("Result: %d \n", count);
   exec SQL commit;
   return;
}

void task2()
{
   printf("Текст запроса: \n");
   printf("2.Поменять местами города, где размещены изделия с самым коротким и самым длинным названием, т. е. изделия с самым коротким названием перевести в город, где размещено изделие с самым длинным названием, и наоборот, изделия с самым длинным названием перевести в город, где размещено изделие с самым коротким названием.\n\n");
   printf("Таблица до выполнения запроса:\n");
   print_table();
   exec SQL begin;
   printf("Выполение запроса... \n");
   exec SQL
     update j set town = (
      case 
        when length(j.name) = (select max(length(name)) from j) 
            then (select j1.town 
                  from j j1 
                  where length(j1.name) = (select min(length(name)) from j) 
                  order by j1.town 
                  limit 1)
            else (select j2.town 
                  from j j2 
                  where length(j2.name) = (select max(length(name)) from j) 
                  order by j2.town 
                  limit 1)
      end
      )
      where length(j.name) = (select min(length(name)) from j) 
         or length(j.name) = (select max(length(name)) from j);


   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка запроса update! Код: %d (%s)\n Текст ошибки%s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL rollback;
      return;
   }
   printf("Обновлено(-а) %d строк(-и). \n", sqlca.sqlerrd[2]);
   exec SQL commit;
   printf("\nТаблица после выполнения запроса:\n");
   print_table();
   return;
}


void task3()
{
   printf("\nТекст запроса: \n");
   printf("3.	Найти детали, имеющие поставки, вес которых меньше среднего веса поставок этой детали для изделий из Лондона.\n\n");
   printf("Объявление курсора...\n");
   EXEC SQL BEGIN DECLARE SECTION;
   char n_det[6];
   int amount;
   float avg;
   EXEC SQL END DECLARE SECTION;
   exec SQL declare curs1 CURSOR for
         SELECT DISTINCT spj.n_det
         FROM spj
         JOIN p ON spj.n_det = p.n_det
         WHERE spj.amount * p.ves < (
            SELECT AVG(spj_inner.amount * p_inner.ves)
            FROM spj AS spj_inner
            JOIN p AS p_inner ON spj_inner.n_det = p_inner.n_det
            JOIN j AS j_inner ON spj_inner.n_izd = j_inner.n_izd
            WHERE j_inner.town = 'Лондон' AND spj_inner.n_det = spj.n_det
         );


   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка обявления курсора! Код: %d (%s)\n Текст ошибки: %s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL rollback;
      return;
   }
   printf("Открытие курсора...\n");
   exec SQL begin;
   exec SQL OPEN curs1;
   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка открытия курсора! Код: %d (%s)\n Текст ошибки: %s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL close curs1;   
      exec SQL rollback;
      return;
   }
   printf("Получение результата...\n");
   int row_count = 0;
   while (1)
   {
      exec SQL FETCH curs1 INTO :n_det;
      if (sqlca.sqlcode < 0) {
         printf("Ошибка получения строки! Код: %d (%s)\n Текст ошибки: %s\n",
            sqlca.sqlcode,
            sqlca.sqlstate,
            sqlca.sqlerrm.sqlerrmc);
         exec SQL close curs1;   
         exec SQL rollback;
         return;
      }
      if (sqlca.sqlcode == 100) break;
      if (row_count == 0) printf("n_det\n");
      printf("%s\n", n_det);
      row_count++;
   }
   printf("Закрытие курсора...\n");
   exec SQL close curs1;
   exec SQL commit;
   if (row_count == 0) printf("Данные не найдены.");
   else printf("Результат: %d строк(-а/и).\n", row_count);
   return;
}

void task4()
{
   printf("Текст запроса: \n");
   printf("4.Выбрать поставщиков, не поставляющих ни одной из деталей, поставляемых поставщиками, находящимися в Лондоне.\n\n");
   printf("Объявление курсора...\n");
   EXEC SQL BEGIN DECLARE SECTION;
   char n_post[6];
   EXEC SQL END DECLARE SECTION;
   exec SQL declare curs2 CURSOR for
         SELECT n_post
         FROM s
         EXCEPT
         SELECT DISTINCT s1.n_post
         FROM spj s1
         JOIN spj s2 ON s1.n_det = s2.n_det
         WHERE s2.n_post IN (SELECT n_post
                             FROM s
                             WHERE town = 'Лондон'
                            );


   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка объявления курсора! Код: %d (%s)\n Текст ошибки: %s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL rollback;
      return;
   }
   printf("Открытие курсора...\n");
   exec SQL begin;
   exec SQL OPEN curs2;
   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка открытия курсора! Код: %d(%s)\n Текст ошибки: %s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL close curs2;
      exec SQL rollback;
      return;
   }
   printf("Получение результата...\n");
   int row_count = 0;
   while (1)
   {
      exec SQL FETCH curs2 INTO :n_post;
      if (sqlca.sqlcode < 0) {
         printf("Ошибка получения строки! Код: %d (%s)\n Текст ошибки: %s\n",
            sqlca.sqlcode,
            sqlca.sqlstate,
            sqlca.sqlerrm.sqlerrmc);
         exec SQL close curs2;   
         exec SQL rollback;
         return;
      }
      if (sqlca.sqlcode == 100) break;
      if (row_count == 0) printf("n_post\n");
      printf("%s\n", n_post);
      row_count++;
   }
   printf("Закрытие курсора...\n");
   exec SQL close curs2;
   exec SQL commit;
   if (row_count == 0) printf("Данные не найдены.");
   else printf("Результат: %d строк(-а/и).\n", row_count);
   return;
}

void task5()
{
   printf("\nТекст запроса: \n");
   printf("5.Выдать полную информацию о поставщиках, выполнивших поставки ТОЛЬКО с объемом от 200 до 500 деталей.\n");
   printf("Объявление курсора...\n");
   EXEC SQL BEGIN DECLARE SECTION;
   char n_post[6];
   char name[40];
   char reiting[6];
   char town[40];
   int name_;
   int town_;
   int reiting_;
   EXEC SQL END DECLARE SECTION;
   exec SQL
   declare curs3 CURSOR for
            SELECT *
            FROM s
            EXCEPT
            SELECT *
            FROM s
            WHERE s.n_post IN(SELECT spj.n_post
                              FROM spj
                              WHERE spj.amount < 200
                              OR spj.amount > 500 );


   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка объявления курсора! Код: %d (%s)\n Текст ошибки: %s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL rollback;
      return;
   }
   printf("Открытие курсора...\n");
   exec SQL begin;
   exec SQL OPEN curs3;
   if (sqlca.sqlcode < 0)
   {
      printf("Ошибка открытия курсора! Код: %d(%s)\n Текст ошибки: %s\n",
         sqlca.sqlcode,
         sqlca.sqlstate,
         sqlca.sqlerrm.sqlerrmc);
      exec SQL close curs3;
      exec SQL rollback;
      return;
   }
   printf("Получение результата...\n");
   int row_count = 0;
   while (1)
   {
      exec SQL FETCH curs3 INTO :n_post, :name indicator name_,:reiting indicator reiting_, :town indicator town_;
      if (sqlca.sqlcode < 0) {
         printf("Ошибка получения строки! Код: %d (%s)\n Текст ошибки: %s\n",
            sqlca.sqlcode,
            sqlca.sqlstate,
            sqlca.sqlerrm.sqlerrmc);
         exec SQL close curs3;
         exec SQL rollback;
         return;
      }
      if (sqlca.sqlcode == 100) break;

      if (row_count == 0) printf("n_post\tname\t\t\ttown\n");
      if(name_<0) strcpy(name,"Нет данных");
      if(town_<0) strcpy(town,"Нет данных");
      if(reiting_<0) strcpy(reiting,"Нет данных");
      printf("%s\t%s\t%s\t%s\n", n_post, name, reiting, town);
      row_count++;
   }
   printf("Закрытие курсора...\n");
   exec SQL close curs3;
   exec SQL commit;
   if (row_count == 0) printf("Данные не найдены.");
   else printf("Результат: %d строк(-а/и).\n", row_count);
   //return;
}
