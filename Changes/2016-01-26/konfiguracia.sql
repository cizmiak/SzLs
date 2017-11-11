--Zaznamy/PlatneDo_2014-02-10/BOZP
use SpravaZmluv
go

insert dbo.Konfiguracia(Nastavenie, Hodnota, PlatnostOd, PlatnostDo)
select
	'Report'
	,replace(Hodnota, 'Zaznamy/', 'Zaznamy/PlatneDo_2016-02-20/')
	,PlatnostOd
	,'2016-02-20'
from dbo.Konfiguracia k
where
	PlatnostDo is null and PlatnostOd is not null
	and
	(
	Hodnota = 'Zaznamy/BOZP'
	or
	Hodnota like 'Zaznamy/OPP_%'
	)

update dbo.Konfiguracia
set PlatnostOd = '2016-02-20'
where
	PlatnostDo is null and PlatnostOd is not null
	and
	(
	Hodnota = 'Zaznamy/BOZP'
	or
	Hodnota like 'Zaznamy/OPP_%'
	)

insert dbo.Konfiguracia(Nastavenie, Hodnota)
values('Report','Zaznamy/BOZP_Kamionisti')
