# Moduł 11 – Aplikacje stanowe i bazy danych

Bazując na wiedzy o StatefulSets i bazach danych w Kubernetes możesz teraz przeanalizować, w jaki sposób przechowywać stan aplikacji. Jeżeli nie masz swojego systemu, to wykonaj mentalne ćwiczenie „jakie wartości fajnie by było mieć”.

* Czy wykorzystasz StatefulSets dla aplikacji? Dlaczego? Czy da się usunąć stan z aplikacji?
* Stan to baza danych czy może też sesyjność/stanowość procesu w aplikacji?

    Generalnie unikałbym stanu w aplikacjach. Jeśli musiałby mieć to raczej z wykorzystaniem zewnętrznego session provider (np. Redis Session) lub bazy danych.

    W przypadku baz danych można ich użyć w modelu Platform-as-a-Service.

* Jeżeli baza danych w Kubernetes to dlaczego w nim, a nie maszyna wirtualna i/lub gotowa usługa?

    Nie przewiduje bazy w K8s.

* Jaki typ bazy danych danych użyjesz w Kubernetes? Czy jest ona gotowa do współpracy z nim?

        Możliwe jest zastosowanie PostgreSQL i wykorzystanie Crunchy Data PostgreSQL Operator lub zalando/postgres-operator, ale to wymaga zmian.