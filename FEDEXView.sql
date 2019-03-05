
SELECT TOH.PickListComment, Erp.TFOrdHed_UD.Del_CustID_c as CustID, Erp.TFOrdHed_UD.Del_Name_c as Destination, Erp.TFOrdHed_UD.Del_Address1_c as Address1,
	   Erp.TFOrdHed_UD.Del_Address2_c as Address2, Erp.TFOrdHed_UD.Del_Address3_c as Address3, 
	   Erp.TFOrdHed_UD.Del_City_c as City, Erp.TFOrdHed_UD.Del_State_c as State,
	   Erp.TFOrdHed_UD.Del_Country_c as Country, Erp.TFOrdHed_UD.Del_Zip_c as ZipCode, 
       TOH.OrderDate, TOH.TFOrdNum as OrderNum, 
	    POTable.PONum,'n/a' as FedExNum,
	   f.Name,
	   (sum(Erp.TFOrdDtl.SellingQty) - sum(Erp.TFOrdDtl.SellingShippedQty)) as 'Amount Left to Ship',
	   ( SELECT DISTINCT  p.ExpLicNumber as 'data()'
	     FROM  erp.TFOrdDtl iTF
         inner join erp.part p on p.partnum = iTF.partnum 
		 where iTF.TfOrdNum = TOH.TFOrdNum
         FOR XML PATH('')
		 )as 'Parts' , 
		 --test this case 
				case 
					when erp.TFOrdHed_UD.Del_Type_c = 'One Time Address' then 'FGS'
					when erp.TFOrdHed_UD.Del_Type_c = 'Hospital' then (select s.ShipViaCode
																		from erp.shipto s
																		join erp.customer c on c.custnum = s.CustNum and c.company = s.company
																		where s.company = 'bio02' and c.custid = erp.TFOrdHed_UD.Del_CustID_c and s.ShipToNum = erp.TFOrdHed_UD.Del_ShipToNum_c)
				    when erp.TFOrdHed_UD.Del_Type_c = 'Distributor / Rep' then RepShipVias.ShipViaCode_c
					else 'FGS'
					end as 'ShipVia' 
FROM   Erp.TFOrdHed TOH
INNER JOIN ERP.TFOrdDtl on Erp.TFOrdDtl.TFOrdNum = TOH.TFOrdNum
INNER JOIN erp.UserFile f on TOH.EntryPerson = f.DcdUserID
INNER JOIN Erp.TFOrdHed_UD ON TOH.SysRowID = Erp.TFOrdHed_UD.ForeignSysRowID
LEFT JOIN ( select  o.PONum, t.TFOrdNum, o.OrderNum from erp.TFOrdHed t
			INNER JOIN erp.OrderHed_UD u on t.TFOrdNum = u.TFOrdNum_c
			INNER JOIN erp.OrderHed o on u.ForeignSysRowID = o.SysRowID ) as POTable on POTable.TFOrdNum = TOH.TFOrdNum
left join (select v.Name as 'dist',v.ShipViaCode, p.Name, u.RepId_c, u.ShipViaCode_c
			from Vendor v 
			join erp.VendorPP p on v.vendornum = p.vendornum and p.company = v.company
			join erp.VendorPP_UD u on p.SysRowID = u.ForeignSysRowID 
			where v.Company = 'bio02'  and U.ShipViaCode_c != '') as RepShipVias on RepShipVias.RepID_c = erp.TFOrdHed_UD.Del_ShipID_c
WHERE TOH.Company = 'bio02' 
GROUP BY 
	   Erp.TFOrdHed_UD.ForeignSysRowID,TOH.TFOrdNum, Erp.TFOrdHed_UD.Del_CustID_c, Erp.TFOrdHed_UD.Del_Name_c, 
	   Erp.TFOrdHed_UD.Del_Address2_c, Erp.TFOrdHed_UD.Del_Address3_c, erp.TFOrdHed_UD.Del_ShipID_c,
	   Erp.TFOrdHed_UD.Del_City_c, Erp.TFOrdHed_UD.Del_State_c,
	   Erp.TFOrdHed_UD.Del_Country_c, Erp.TFOrdHed_UD.Del_Zip_c, erp.TFOrdHed_UD.Del_ShipToNum_c ,
       TOH.OrderDate,  Erp.TFOrdHed_UD.Del_Address1_c,erp.TFOrdHed_UD.Del_Type_c,
	   POTable.PONum, f.Name, RepShipVias.ShipViaCode_c, toh.plant,
	   TOH.PickListComment, TOH.ShipViaCode
HAVING  (sum(Erp.TFOrdDtl.SellingQty) - sum(Erp.TFOrdDtl.SellingShippedQty)) != 0
				 and TOH.PickListComment = ''
				 and TOH.OrderDate >= CAST(GetDATE() as Date)
				 and TOH.Plant = 'mfgsys'
					 and 
						(case when erp.TFOrdHed_UD.Del_Type_c = 'One Time Address' then 'FGS' 
						 when erp.TFOrdHed_UD.Del_Type_c = 'Hospital' then (select s.ShipViaCode
																			from erp.shipto s
																			join erp.customer c on c.custnum = s.CustNum and c.company = s.company
																			where s.company = 'bio02' and c.custid = erp.TFOrdHed_UD.Del_CustID_c and s.ShipToNum = erp.TFOrdHed_UD.Del_ShipToNum_c)
						when erp.TFOrdHed_UD.Del_Type_c = 'Distributor / Rep' then RepShipVias.ShipViaCode_c
						else 'FGS' end) like 'F%'


union 


SELECT o.PickListComment, c.CustID, s.Name as Destination, s.Address1, s.Address2, s.Address3,
	   s.City, s.State, s.Country, s.ZIP, o.OrderDate, o.OrderNum, O.PONum, cud.FedExNum_c,
	   f.Name,
	   Case when od.OpenLine = 1 then 1
	   else 0 end as 'Amount Left to Ship'
	   ,
	    ( SELECT DISTINCT  p.ExpLicNumber as 'data()'
	     FROM  erp.OrderDtl oTF
         inner join erp.part p on p.partnum = oTF.partnum 
		 where oTF.OrderNum = o.OrderNum
         FOR XML PATH('')
		 )as 'Parts' , o.ShipViaCode	
FROM Erp.OrderHed o
INNER JOIN ERP.OrderDtl od on o.OrderNum = od.OrderNum and od.company = o.company
inner join erp.UserFile f on o.EntryPerson = f.DcdUserID 
INNER JOIN Erp.Customer c on o.CustNum = c.CustNum and  c.company = o.company
INNER JOIN Erp.Customer_UD cud on c.sysRowID = cud.ForeignSysrowID
INNER JOIN Erp.OrderHed_UD u on o.SysRowID = u.ForeignSysRowID 
INNER JOIN Erp.ShipTo s on o.CustNum = s.CustNum and o.ShiptoNum = s.ShipToNum and s.company = o.company
WHERE o.Company = 'bio02' and od.OpenLine = 1 and o.PickListComment = '' and o.CounterSale = 0 and o.OrderDate >= CAST(GetDATE() as Date) and o.ShipViaCode like 'F%'

