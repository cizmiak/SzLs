use SpravaZmluv
go
alter table dbo.SkoleniePosluchac add I bit
alter table dbo.SkoleniePosluchac add A bit
alter table dbo.SkoleniePosluchac add B bit
alter table dbo.SkoleniePosluchac add C bit
alter table dbo.SkoleniePosluchac add D bit
alter table dbo.SkoleniePosluchac add E bit
alter table dbo.SkoleniePosluchac add W1 bit
alter table dbo.SkoleniePosluchac add W2 bit
alter table dbo.SkoleniePosluchac add G bit
alter table dbo.SkoleniePosluchac add II bit
alter table dbo.SkoleniePosluchac add Z bit
alter table dbo.SkoleniePosluchac add C_BezVodickehoOpravnenia bit
alter table dbo.SkoleniePosluchac add W1_BezVodickehoOpravnenia bit
alter table dbo.SkoleniePosluchac add Z_PocetHodin float
go

--select
update sp set
	PreukazVydany = isnull(sp.PreukazVydany, s.PreukazyVydane),
	PreukazVydal = isnull(sp.PreukazVydal, s.PreukazyVydal),
	CisloPreukazu = isnull(sp.CisloPreukazu, s.CisloPreukazu),

	I = s.I,
	A = s.A,
	B = s.B,
	C = s.C,
	D = s.D,
	E = s.E,
	W1 = s.W1,
	W2 = s.W2,
	G = s.G,
	II = s.II,
	Z = s.Z,

	C_BezVodickehoOpravnenia = s.C_BezVodickehoOpravnenia,
	W1_BezVodickehoOpravnenia = s.W1_BezVodickehoOpravnenia,
	Z_PocetHodin = s.Z_PocetHodin
from
	dbo.Skolenie s
	inner join dbo.SkoleniePosluchac sp
		on sp.SkolenieID = s.ID
where
(
	s.PreukazyVydane is not null
	or
	isnull(s.PreukazyVydal, s.CisloPreukazu) is not null
	or
	coalesce(s.I, s.A, s.B, s.C, s.D, s.E, s.W1, s.W2, s.G, s.II, s.Z, s.C_BezVodickehoOpravnenia, s.W1_BezVodickehoOpravnenia) is not null
	or
	s.Z_PocetHodin is not null
)
go