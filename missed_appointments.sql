select
	ta.district,
	ta.facility_name,
	concat(pn.given_name, ' ', pn.family_name) Full_name,
	pn.given_name first_name,
	pn.family_name last_name,
	pp.gender,
	pp.birthdate,
	pp.birthdate_est,
	cd.home_phone_number,
	cd.cell_phone_number,
	cd.work_phone_number,
	idf.identifier ART_number,
	idf1.identifier Spid,
	idf2.identifier Npid,
	padd.home_traditional_authority_id TA,
	padd.home_village_id Home_Village,
	padd.landmark nearest_landmark,
	md.description follow_up_agreement,
	min(ta.appointment_date) missed_appointment_date,
	ta.uuid missed_appointment_uuid,
	ta.appointment_id,
	DATE_PART('day', now() - ta.appointment_date) days_missed
from
	(
	select
		distinct loc.district,
		cast(loc.facility_name as CHAR(255)) facility_name,
		loc.prime_partner,
		date(a.appointment_date) appointment_date,
		a.uuid,
		a.appointment_id,
		e.person_id,
		date(e.visit_date) visit_date,
		e.encounter_id
	from
		encounters e
	left join appointments a on
		e.encounter_id = a.encounter_id
	join (
		select
			s.site_id,
			s.site_name facility_name,
			l.name district,
			pp.prime_partner
		from
			sites s
		join locations l on
			s.parent_district = l.location_id
		join prime_partners pp on
			s.partner_code = pp.partner_code) loc on
		cast(trim(leading '0' from right(cast(e.person_id as text), 5)) as integer) = cast(loc.site_id as integer)
	where
		e.voided = '0'
		and a.voided = '0'
		and e.program_id = 1
		and a.concept_id = 5373
		and date(appointment_date) between (
		select
			cast(date_trunc('quarter', current_date) as date)) and date(NOW()) ) ta
left join (
	select
		person_id,
		identifier
	from
		identifiers
	where
		identifier_type = '20835'
		and voided = '0' ) idf on
	ta.person_id = idf.person_id
left join (
	select
		person_id,
		identifier
	from
		identifiers
	where
		identifier_type = '20834'
		and voided = '0'
		and length(identifier)>6 ) idf1 on
	ta.person_id = idf1.person_id
left join (
	select
		person_id,
		identifier
	from
		identifiers
	where
		identifier_type = '20834'
		and voided = '0'
		and length(identifier)= 6 ) idf2 on
	ta.person_id = idf2.person_id
left join person_addresses padd on
	padd .person_id = ta.person_id
left join followup fu on
	ta.person_id = fu.person_id
left join master_definitions md on
	md.master_definition_id = fu.concept_id
join people pp on
	pp.person_id = ta.person_id
join person_names pn on
	pn.person_id = ta.person_id
join contact_details cd on
	cd.person_id = ta.person_id
where
	fu.voided = '0'
	and md.voided = '0'
	and padd.voided = '0'
	and pp.voided = '0'
	and cd.voided = '0'
	and ta.person_id not in (
	select
		distinct abb.person_id
	from
		(
		select
			ab.person_id
		from
			(
			select
				distinct e.person_id
			from
				encounters e
			left join (
				select
					distinct appts1.person_id person,
					case
						when appts1.appointment_status = 'appointment within quarter' then '1'
						else 0
					end as appt_status
				from
					(
					select
						e2.person_id person_id ,
						a2.appointment_date,
						case
							when date(a2.appointment_date) between (
							select
								cast(date_trunc('quarter', current_date) as date)) and (
							select
								cast(date_trunc('quarter', current_date) + interval '3 months' - interval '1 day' as date)) then 'appointment within quarter'
							else 'not within quarter'
						end appointment_status
					from
						encounters e2
					join appointments a2 on
						e2.encounter_id = a2.encounter_id
					where
						e2.program_id = '1'
						and e2.voided = '0'
						and a2.concept_id = '5373'
						and a2.voided = '0'
						and a2.appointment_date between (
						select
							cast(date_trunc('quarter', current_date) as date)) and (
						select
							cast(date_trunc('quarter', current_date) + interval '3 months' - interval '1 day' as date)) ) appts1
				group by
					person,
					appointment_status )appts on
				e.person_id = appts.person
			join (
				select
					s.site_id,
					cast(s.site_name as CHAR(255)) facility_name,
					l.name district,
					pp.prime_partner
				from
					sites s
				join locations l on
					s.parent_district = l.location_id
				join prime_partners pp on
					s.partner_code = pp.partner_code) loc on
				cast(trim(leading '0' from right(cast(e.person_id as text), 5)) as integer) = cast(loc.site_id as integer)
			where
				e.voided = '0'
				and e.program_id = '1'
				and e.encounter_type_id = 81
				and date(visit_date) between (
				select
					cast(date_trunc('quarter', current_date) as date)) and date(NOW())
		union all
			select
				distinct e.person_id
			from
				encounters e
			join (
				select
					distinct loc.district,
					cast(loc.facility_name as CHAR(255)) facility_name,
					loc.prime_partner,
					date(a.appointment_date) appointment_date,
					e.person_id,
					date(e.visit_date) visit_date
				from
					encounters e
				left join appointments a on
					e.encounter_id = a.encounter_id
				join (
					select
						s.site_id,
						s.site_name facility_name,
						l.name district,
						pp.prime_partner
					from
						sites s
					join locations l on
						s.parent_district = l.location_id
					join prime_partners pp on
						s.partner_code = pp.partner_code) loc on
					cast(trim(leading '0' from right(cast(e.person_id as text), 5)) as integer) = cast(loc.site_id as integer)
				where
					e.voided = '0'
					and a.voided = '0'
					and e.program_id = 1
					and a.concept_id = 5373
					and date(appointment_date) between (
					select
						cast(date_trunc('quarter', current_date) as date)) and date(NOW()) ) tap on
				(e.person_id = tap.person_id
					and date(e.visit_date)>date(tap.visit_date))
			join (
				select
					s.site_id,
					cast(s.site_name as CHAR(255)) facility_name,
					l.name district,
					pp.prime_partner
				from
					sites s
				join locations l on
					s.parent_district = l.location_id
				join prime_partners pp on
					s.partner_code = pp.partner_code) loc on
				cast(trim(leading '0' from right(cast(e.person_id as text), 5)) as integer) = cast(loc.site_id as integer)
			where
				e.person_id not in (
				select
					distinct e.person_id
				from
					encounters e
				left join (
					select
						distinct appts1.person_id person,
						case
							when appts1.appointment_status = 'appointment within quarter' then '1'
							else 0
						end as appt_status
					from
						(
						select
							e2.person_id person_id ,
							a2.appointment_date,
							case
								when date(a2.appointment_date) between (
								select
									cast(date_trunc('quarter', current_date) as date)) and (
								select
									cast(date_trunc('quarter', current_date) + interval '3 months' - interval '1 day' as date)) then 'appointment within quarter'
								else 'not within quarter'
							end appointment_status
						from
							encounters e2
						join appointments a2 on
							e2.encounter_id = a2.encounter_id
						where
							e2.program_id = '1'
							and e2.voided = '0'
							and a2.concept_id = '5373'
							and a2.voided = '0'
							and a2.appointment_date between (
							select
								cast(date_trunc('quarter', current_date) as date)) and (
							select
								cast(date_trunc('quarter', current_date) + interval '3 months' - interval '1 day' as date)) ) appts1
					group by
						person,
						appointment_status )appts on
					e.person_id = appts.person
				join (
					select
						s.site_id,
						cast(s.site_name as CHAR(255)) facility_name,
						l.name district,
						pp.prime_partner
					from
						sites s
					join locations l on
						s.parent_district = l.location_id
					join prime_partners pp on
						s.partner_code = pp.partner_code) loc on
					cast(trim(leading '0' from right(cast(e.person_id as text), 5)) as integer) = cast(loc.site_id as integer)
				where
					e.voided = '0'
					and e.program_id = '1'
					and e.encounter_type_id = 81
					and date(visit_date) between (
					select
						cast(date_trunc('quarter', current_date) as date)) and date(NOW()) )
					and e.voided = '0'
					and e.encounter_type_id = 81
					and e.program_id = 1
					and date(e.visit_date) between (
					select
						date((
						select
							cast(date_trunc('quarter', current_date) as date))::date - cast('31 days' as interval))) and (
					select
						cast(date_trunc('quarter', current_date) as date)) ) ab)abb )
	and DATE_PART('day', now() - ta.appointment_date) < 120
group by
	ta.district,
	ta.facility_name,
	ta.prime_partner,
	concat(pn.given_name, ' ', pn.family_name),
	ta.appointment_date,
	pn.given_name,
	pn.family_name,
	pp.gender,
	pp.birthdate_est,
	cd.home_phone_number,
	cd.cell_phone_number,
	cd.work_phone_number,
	idf.identifier,
	idf1.identifier,
	idf2.identifier,
	padd.home_traditional_authority_id,
	padd.home_village_id,
	padd.landmark,
	pp.birthdate,
	ta.uuid,
	ta.appointment_id,
	md.description ;

