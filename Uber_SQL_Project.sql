CREATE TABLE Uber (
    BookingID             VARCHAR(20) PRIMARY KEY,
    TripDate              DATE,
    TripTime              TIME,
    BookingStatus          VARCHAR(30),

    CustomerID            VARCHAR(20),
    VehicleType            VARCHAR(15),

    PickupLocation         VARCHAR(100),
    DropLocation           VARCHAR(100),

    CustomerCancelledRides INT,
    CustomerCancelReason   VARCHAR(100),

    DriverCancelledRides   INT,
    DriverCancelReason     VARCHAR(100),

    IncompleteRides        INT,
    IncompleteReason       VARCHAR(100),

    Amount                 DECIMAL(10,2),
    RideDistanceKM         DECIMAL(8,2),

    DriverRating           DECIMAL(2,1),
    CustomerRating         DECIMAL(2,1),

    PaymentMethod          VARCHAR(20)
);

SELECT * FROM Uber;

select 
   count(*) as Total_Booking,
   sum(case when BookingStatus = 'Completed' then 1 else 0 end ) as Complete_Booking,
   sum(case when BookingStatus like 'Canc%' then 1 else 0 end ) as Cancelled_Booking,
   to_char(sum(amount), '"RS "999,999,999.00') as Total_Revenue,
   to_char(avg(amount), '"RS "999,999,999.00') as Avg_Revenue,
   concat(round(sum(ridedistanceKM),2),' Km') as Total_Distance,
   concat(round(avg(ridedistanceKM),2),' Km') as Avg_Distance
from uber;
   
--1.Business Performance

--How many total rides were booked and how much revenue was generated?
  Select 
     count(*) as Total_Rides,
     to_char(sum(amount), '"RS "999,999,999.00') as Total_Revenue 
  From uber;
  
--What percentage of rides were completed, cancelled, and incomplete?
  Select 
     round(sum(case when Bookingstatus = 'Completed' then 1 else 0 end) * 100.00 / count(*) ,2) as Completed_Rides,
     round(sum(case when Bookingstatus like 'Cance%' then 1 else 0 end) * 100.00 / count(*) ,2) as Cancelled_Rides,
     round(sum(case when Bookingstatus in('Incomplete','No Driver Found') then 1 else 0 end) * 100.00 / count(*) ,2) as Incomplete_Rides
  from uber;

--What percentage of rides were completed, cancelled by Customer & Driver,noDriver Found and incomplete?
  Select 
     Bookingstatus,Count(*) as TotalRides,
     Round(count(*) * 100 / Sum(count(*)) over(),2) as Percentage 
  From uber 
  Group by Bookingstatus;

--What is the average fare and average distance per ride?
  select 
     concat('Rs ',round(avg(amount),2)) as Average_Fare ,
     concat(round(Avg(RideDistanceKM),2),' Km') as Average_Distance 
  from uber
  where bookingStatus='Completed';
  
 --What are the average driver and customer ratings?	
    SELECT
        round(AVG(DriverRating),2) AS Average_Driver_Rating,
        round(AVG(CustomerRating),2) AS Avgerage_Customer_Rating
    FROM Uber;


	
--2.Time Analysis

--What are the peak booking hours?
  select
     to_char(triptime, 'hh12 AM')as PeakHour,
     count(*) as bookingCount
  From uber
  group by PeakHour
  order by BookingCount Desc,peakhour;

--Which time slot (Morning, Afternoon, Evening, Night) generates the most rides?
  Select
     case
        when extract(Hour from Triptime) between 5 and 8 then 'Early Morning 5 AM - 8 AM'
	    when extract(Hour from Triptime) between 9 and 11 then 'Late Morning 9 AM - 11 AM'
		when extract(Hour from Triptime) between 12 and 16 then 'Afternoon 12 PM - 4 PM'
		when extract(Hour from Triptime) between 17 and 20 then 'Evening 5 PM - 8 PM'
	    else 'Night 9 PM - 4 AM'
	    End as TimeSlot,
     Count(*) as Booking_Count
  From uber
  group by Timeslot
  Order by Booking_Count Desc;

--3.Vehicle Performance
--Which vehicle type is most used?
  Select 
     vehicleType,
     Count(*) as Total_Rides
  From uber
  group by vehicletype
  order by total_rides desc;

--Which vehicle type generates the highest revenue and what % of total revenue does it contribute?
  Select
     vehicletype,
     round(sum(amount),2) as Revenue,
     Concat(round(100.00 * sum(amount) / sum(sum(amount)) over(),2),' %') as percentage
  from uber 
  where bookingStatus ='Completed'
  Group by vehicletype
  order by Revenue Desc;
  
--What is the average revenue per km by vehicle type?
  Select 
     Vehicletype,
     concat('Rs ',round(sum(amount)/ sum(RidedistanceKM),2) )as Avg_Revenue_per_KM
  from uber
  where bookingstatus = 'Completed'
  group by vehicletype;


--4.Customer Behavior

--What percentage of customers have cancelled at least one ride?
  select 
     count(distinct customerID) as Total_Customer,
     count(distinct CustomerID) filter(where CustomerCancelledRides = 1) as Customer_Cancelled_Rides,
	 concat(Round(count(distinct CustomerID) 
	   filter(where CustomerCancelledRides = 1) * 100.00 / count(distinct customerID),2),' %')  as CancelationRate
  from uber;
  
--Who are the top 10 highest-spending customers?
  Select 
     CustomerID,to_char(sum(Amount),'"Rs"999,999,999.00') as revenue
  from uber 
  where Bookingstatus = 'Completed'
  group by CustomerId 
  order by revenue Desc limit 10 ;


--5.Driver Reliability

--What are the top driver cancellation reasons?
  select 
     DrivercancelReason as Driver_cancel_Reason,Count(*) AS Total_Cancellations
  from uber
  where drivercancelledRides = 1
  group by DrivercancelReason 
  order by Total_Cancellations desc;


--6.Location Intelligence

--Which pickup locations generate the most completed rides?
  select 
     pickuplocation,
     sum(case when bookingstatus = 'Completed' then 1 else 0  end ) as Complete_rides
  from uber 
  group by pickuplocation
  order by Complete_rides desc ;

--Which pickup-drop pairs generate the highest average fare?
  select 
     pickuplocation,
	 droplocation,
     round(avg(amount),2) as avg_trip_amount
  from uber
  where bookingStatus = 'Completed'
  group by pickuplocation,droplocation
  order by avg_trip_amount Desc;


--7.Revenue & Payments

--How is revenue distributed across payment methods?
  Select 
     paymentMethod,
	 to_char(sum(Amount),'"Rs "999,999,999.00') as Revenue
  From uber 
  where bookingStatus = 'Completed'
  group by paymentmethod
  order by revenue Desc;


--8.Risk & Loss Analysis

--What are the main reasons for incomplete rides and their percentages?
  select 
     incompleteReason, count(*) as total_Reason,
     concat(round(count(*) * 100.00 / sum(count(*)) over() ,2),' %') as Percentage
  from uber 
  where incompleterides = 1
  group by incompleteReason ;
   