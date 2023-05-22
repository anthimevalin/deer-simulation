;extension time has been used to calculate the distances between times in terms of days
extensions [time CSV]



;breed of agents
breed[deer a-deer]
breed[hunters hunter]
breed[cars car]


globals [
  accident-count ;variable to hold number of deer car collisions
  shot-count-male ;variable to hold number of male deer shot
  shot-count-female ;variable to hold number of female deer shot
  natural-death ;variable to hold deer that die from natural causes
  interval ;variable for number of patches between roads based on number of roads selected
  i ;variable for index
  miles-per-patch ;variable for number of miles for each patch of road
  hours-per-tick ;variable for number of hours gone by per tick
  days ;variable to hold number of days that have gone by since start of year
  years ;variable to hold number of years that have gone by since start of the simulation
  days-for-plot ;variable to hold number of days that have by since start of the simulation
  date-hunt-start ;variable to hold users input of start of hunting season
  date-hunt-end ;variable to hold users input of end of hunting season
  date-mating-start ;variable to hold users input of start of mating season
  date-mating-end ;variable to hold users input of end of mating season
  days-hunt-start ;variable to hold users input for start of hunting season
  days-hunt-end ;variable to hold users input for end of hunting season
  days-mating-start ;variable to hold users input for start of mating season
  days-mating-end ;variable to hold users input for end of mating season
  condition-hunt-met? ;variable to indicate when the simulation has entered hunting season
  next-year-hunt? ;variable that indicates whether the end of hunting season is in the following year
  next-year-mate? ;variable that indicates whether the end of mating season is in the following year
  file ;file where all the data is stored


  columns ;columns for the file

]

deer-own [
  female? ;whether deer is female or male
  pregnant? ;whether female deer is currently pregnant
  age ;age of deer
  time-pregnant? ;how long female deer has been pregnant
]

;setup function
to setup
  clear-all
  reset-ticks
  set file user-new-file
  ; Check to make sure we actually got a string just in case
  ; The user hits the cancel button.
  if is-string? file
  [

    ; If the file already exists, we begin by deleting it, otherwise new data would be appended to the old contents
    if file-exists? file
      [ file-delete file ]

    set file (word file ".csv")
    file-open file
    set columns [["year" "day" "cumulative_days" "male_deer_population" "female_deer_population" "total_deer_population" "number_of_hunters" "harvested_deer" "number_of_deer_hit"] []]

    csv:to-file file columns
    file-close
  ]
  ;alter the number of patches in the environment based on size-world button
  resize-world -16 * size-world 16 * size-world -16 * size-world 16 * size-world

  set days 0
  set days-for-plot 0
  set years 0

  set condition-hunt-met? false

  ;call create-terrain function to initialize the patches color to white to represent winter
  create-terrain

  ;calculate number of miles on each patch of road based on the total amount of road miles
  set miles-per-patch ((miles-per-road * num-road) / (max-pxcor - min-pxcor + 1))
  ;based on the miles in patch and average speed of the car, amount of hours per tick is calculated
  set hours-per-tick (miles-per-patch / average-speed-cars)

  ;allow for user to input the start and end date for hunting season and calculates the dates distances from the start of the year in days
  set date-hunt-start user-input "Start date of hunting season (MM-DD): \r\n (e.g., for PA 11-28) "

  set days-hunt-start time:difference-between (time:create "01-01") (time:create date-hunt-start) "days"

  set date-hunt-end user-input "End date of hunting season (MM-DD): \r\n (e.g., for PA 12-12)"
  set days-hunt-end time:difference-between (time:create "01-01") (time:create date-hunt-end) "days"

  ;allow for user to input the start and end date for huting season and calculates the dates distances from the start of the year in days
  set date-mating-start user-input "Start date of mating season (MM-DD): \r\n (e.g., for PA 12-01)"
  set days-mating-start time:difference-between (time:create "01-01") (time:create date-mating-start) "days"

  set date-mating-end user-input "End date of mating season (MM-DD): \r\n (e.g., for PA 03-01)"
  set days-mating-end time:difference-between (time:create "01-01") (time:create date-mating-end) "days"

  ;to indicate whether the end dates are in the following year
  ifelse days-hunt-start > days-hunt-end [ set next-year-hunt? true ] [ set next-year-hunt? false ]
  ifelse days-mating-start > days-mating-end [ set next-year-mate? true ] [ set next-year-mate? false ]

  ;create deer agents assigned to be adult female, based on value on num-female-deer slider
  create-deer num-female-deer [
    set shape "female deer"
    set size 0.7
    set color brown
    setxy random-pxcor random-pycor
    set female? true
    set pregnant? false
    set age ((730 * 24) / hours-per-tick)

  ]

  ;create deer agents assigned to be adult male, based on value on num-male-deer slider
  create-deer num-male-deer [
    set shape "deer"
    set size 0.7
    set color brown
    setxy random-pxcor random-pycor
    set female? false
    set age ((730 * 24) / hours-per-tick)

  ]

  ;create a number of roads based on value on num-road slider with equal distance between eachother
  set interval round((max-pycor - min-pycor) / (num-road + 1))
  set i 0
  repeat num-road [
    ask patches with [pycor = round((interval * (i + 1)) + min-pycor)  and pxcor >= min-pxcor and pxcor <= max-pxcor] [set pcolor gray]
    ;create car agents on each road based on value on num-car-per-road slider
    create-cars num-car-per-road [
      set shape "car"
      setxy random-pxcor round((interval * (i + 1)) + min-pycor)
      set size 0.7
    ]
    set i i + 1
  ]

  set accident-count 0
  set shot-count-male 0
  set shot-count-female 0
  if is-string? file [
    file-open file
    let initial-values (list years days days-for-plot (num-male-deer * 1000) (num-female-deer * 1000) ((num-male-deer + num-female-deer) * 1000) (num-hunter * 1000) ((shot-count-male + shot-count-female) * 1000) (accident-count * 1000))
    set columns lput initial-values columns
    csv:to-file file columns
    file-close
  ]



end



;deers movement function
to deer-move
  right random 360
  forward 0.5
end

;hunters movement function
to hunter-move
  right random 360
  forward 0.25
end

;cars movement function
to car-move
  set heading 90
  forward 1

end

;hunt function for hunters
to hunt
  ;for deer in same patch as hunter, deer has a certain probability, given by harvest-probability slider, to die
  let prey one-of deer in-radius 1.2
  if prey != nobody [
    ifelse random-float 1 < harvest-probability  [
      ask prey [
        if female? = true [ set shot-count-female (shot-count-female + 1) ]
        if female? = false [ set shot-count-male (shot-count-male + 1) ]
        die
      ]
    ]
    [    ]
  ]

end

;mate function for deer
to mate
  ;ask male deer aged one and half years (548 days)
  ask deer with [ female? = false and age >= ((548 * 24) / hours-per-tick) ] [
    ;ask female deer aged one and half years (548 days) in radius 1 of the male deer
    if any? deer with [ female? = true and pregnant? = false and age >= ((548 * 24) / hours-per-tick) ] in-radius 1 [
      if random-float 1 < mate-probability [
        ask deer with [ female? = true and pregnant? = false ] in-radius 1 [
          set pregnant? true
          set time-pregnant? 0
        ]



      ]
    ]
  ]
end

;accident function
to accident
  let prey one-of deer-here
  if prey != nobody [
    ifelse random-float 1 < accident-probability  [
      set accident-count accident-count + 1
      ask prey [
        die
      ]
    ]
    [    ]
  ]
end


;terrain function
to create-terrain
  ;winter from 1st Decemeber to 30th January
  if (days >= 0 and days < 60 ) or (days >= 335) [
    ask patches [
      ifelse pcolor = gray [] [
      set pcolor white
      ]
   ]
  ]
  ;spring from 1st February to 30th April
  if (days >= 60 and days < 152 ) [
    ask patches [
      ifelse pcolor = gray [ ] [
        set pcolor 65
      ]
    ]
  ]
  ;summer from 1st May to 31st August
  if (days >= 152 and days < 244 )[
    ask patches [
      ifelse pcolor = gray [ ] [
        set pcolor 62
      ]
    ]
  ]
  ;autumn from 1st September to 30th November
  if (days >= 244 and days < 335 )[
    ask patches [
      ifelse pcolor = gray [ ] [
        set pcolor 23
      ]
    ]
  ]

end

;report deer hit by cars
to-report accidents
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days accident-count]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot accident-count]

  report accident-count
end

;report total deer population
to-report number-of-total-deer
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days count deer]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot count deer]

  report count deer
end

;report total female deer population
to-report number-of-female-deer
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days (count deer with [female? = true])]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot (count deer with [female? = true])]

  report (count deer with [female? = true])
end

;report total male deer population
to-report number-of-male-deer
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days (count deer with [female? = false])]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot (count deer with [female? = false])]

  report (count deer with [female? = false])
end

;report total male deer shot
to-report shots-male
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days shot-count-male]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot shot-count-male]

  report shot-count-male
end

;report total female deer shot
to-report shots-female
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days shot-count-female]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot shot-count-female]

  report shot-count-female
end

;report total deer shot
to-report shots-total
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days (shot-count-female + shot-count-male)]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot (shot-count-female + shot-count-male)]

  report (shot-count-female + shot-count-male)
end

;report deer that die from natural causes
to-report natural-death-cause
  ;reset graph every year if switch is on
  if reset-data-every-year? = true [plotxy days natural-death]

  ;continuous graph if switch is off
  if reset-data-every-year? = false [plotxy days-for-plot natural-death]

  report natural-death

end

;files content function
to write-to-file
  file-open file
  let initial-values (list years days days-for-plot (count deer with [female? = false] * 1000) (count deer with [female? = true] * 1000) ((count deer with [female? = true] + count deer with [female? = false]) * 1000) (count hunters * 1000) ((shot-count-male + shot-count-female) * 1000) (accident-count * 1000))
  set columns lput initial-values columns
  csv:to-file file columns
  file-close


  file-close
end


;go function
to go
  ;change the terrain based on the day
  create-terrain

  ;create hunters if it is currently hunting season
  if (condition-hunt-met? = false and ((next-year-hunt? = false and (days-hunt-start <= days and days-hunt-end > days)) or (next-year-hunt? = true and ((days-hunt-start <= days and days-hunt-end < days) or (days-hunt-start >= days and days-hunt-end > days))))) [
    set condition-hunt-met? true
    create-hunters num-hunter [
      set shape "person farmer"
      set size 0.5
      set color black
      setxy random-pxcor random-pycor
    ]

  ]

  ;remove all hunters if it is currently not hunting season
  if (condition-hunt-met? = true and ((next-year-hunt? = false and days >= days-hunt-end) or (next-year-hunt? = true and ((days > days-hunt-end and days-hunt-start >= days) or (days < days-hunt-end and days >= days-hunt-start))))) [
    set condition-hunt-met? false
    ask hunters [
      die
    ]
  ]

  ;move deer and update their age
  ask deer [
    deer-move
    set age age + 1

  ]

  ;based on breed and sex of deer, remove them if they reach a certain age
  ask deer with [ female? = true and breed-deer = "White-tailed" ] [ if age >= ((2920 * 24) / hours-per-tick ) [ die (set natural-death natural-death + 1)] ] ;8 years
  ask deer with [ female? = false and breed-deer = "White-tailed" ] [ if age >= ((2190 * 24) / hours-per-tick ) [ die (set natural-death natural-death + 1)] ] ;6 years
  ask deer with [ female? = false and breed-deer = "Mule" ] [ if age >= ((3652 * 24) / hours-per-tick ) [ die (set natural-death natural-death + 1)] ] ;10 years
  ask deer with [ female? = true and breed-deer = "Mule" ] [ if age >= ((4383 * 24) / hours-per-tick ) [ die (set natural-death natural-death + 1)] ] ;12 years

  ;update the time female deer has been pregnant and randomly add 1 or 2 newborn deer agent[s] if pregnancy time has reached a certain number of days varying based on breed
  ask deer with [ female? = true and pregnant? = true and breed-deer = "White-tailed" ] [
    set time-pregnant? time-pregnant? + 1
    if time-pregnant? >= ((201 * 24) / hours-per-tick ) [
      hatch one-of [ 1 2 ] [
          set female? one-of [ true  false]
          if female? = true [set shape "female deer"]
          if female? = false [set shape "deer"]
          set age 0
          set pregnant? false

        ]
      set time-pregnant? 0
      set pregnant? false
    ]
  ]
  ask deer with [ female? = true and pregnant? = true and breed-deer = "Mule"] [
    set time-pregnant? time-pregnant? + 1
    if time-pregnant? >=((203 * 24) / hours-per-tick ) [
      hatch one-of [ 1 2 ] [
          set female? one-of [ true  false]
          if female? = true [set shape "female deer"]
          if female? = false [set shape "deer"]
          set age 0
          set pregnant? false

        ]
      set time-pregnant? 0
      set pregnant? false
    ]
  ]

  ;move hunters and allow them to hunt
   ask hunters [
     hunter-move
     hunt
  ]

  ;move cars and register if accident has occured
  ask cars [
    car-move
    accident
  ]

  ;allow deer to mate if currently in mating season
  if (next-year-mate? = false and days-mating-start <= days and days-mating-end > days) or (next-year-mate? = true and ((days-mating-start <= days and days-mating-end < days) or (days-mating-start >= days and days-mating-end > days))) [
    mate
  ]

  tick

  ;set days based on hours per tick
  set days (days + (hours-per-tick / 24))
  set days-for-plot (days-for-plot + (hours-per-tick / 24))

  ;if new year reset all plots, shot counts and accident counts if the switch is on, reset day number and increase year number
  if days > 365 [
    if reset-data-every-year? = true [
      clear-all-plots
      set shot-count-female 0
      set shot-count-male 0
      set accident-count 0
      set natural-death 0
    ]
    set days 0
    set years years + 1
    set condition-hunt-met? false
  ]

  ;if file exists call write-to-file function
  if is-string? file [write-to-file]

end
@#$#@#$#@
GRAPHICS-WINDOW
233
18
1027
813
-1
-1
4.882
1
10
1
1
1
0
1
1
1
-80
80
-80
80
0
0
1
ticks
30.0

SLIDER
24
320
196
353
num-male-deer
num-male-deer
0
1500
375.0
1
1
NIL
HORIZONTAL

BUTTON
14
604
80
637
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
18
508
190
541
num-hunter
num-hunter
0
1000
633.0
1
1
NIL
HORIZONTAL

BUTTON
88
605
151
638
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
18
556
195
589
harvest-probability
harvest-probability
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
22
67
194
100
num-road
num-road
0
20
1.0
1
1
NIL
HORIZONTAL

PLOT
1068
363
1372
636
Deer Population Over Time
Time (Days)
Deer Population (thousands)
0.0
365.0
0.0
10.0
true
true
"" ""
PENS
"Male" 1.0 0 -13345367 true "" "plot number-of-male-deer"
"Female" 1.0 0 -2064490 true "" "plot number-of-female-deer"
"Total" 1.0 0 -16777216 true "" "plot number-of-total-deer"

SLIDER
24
368
196
401
num-female-deer
num-female-deer
0
1500
1125.0
1
1
NIL
HORIZONTAL

SLIDER
23
407
195
440
mate-probability
mate-probability
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
22
116
194
149
num-car-per-road
num-car-per-road
0
20
2.0
1
1
NIL
HORIZONTAL

PLOT
1058
652
1361
891
Number of Accidents Between Deer and Cars
Time (Days)
Accidents (Thousands)
0.0
365.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot accident-count"

CHOOSER
34
451
172
496
breed-deer
breed-deer
"White-tailed" "Mule"
0

PLOT
1067
83
1370
354
Harvest of Deer Over Time
Time (Days)
Harvest of Deer (thousands)
0.0
365.0
0.0
10.0
true
true
"" ""
PENS
"Male" 1.0 0 -13345367 true "" "plot shots-male"
"Female" 1.0 0 -2064490 true "" "plot shots-female"
"Total" 1.0 0 -16777216 true "" "plot shots-total"

SLIDER
20
12
192
45
size-world
size-world
1
10
5.0
0.25
1
NIL
HORIZONTAL

SLIDER
19
161
198
194
average-speed-cars
average-speed-cars
0
100
31.0
1
1
NIL
HORIZONTAL

INPUTBOX
34
202
183
262
miles-per-road
121000.0
1
0
Number

SWITCH
1068
29
1269
62
reset-data-every-year?
reset-data-every-year?
1
1
-1000

SLIDER
25
269
204
302
accident-probability
accident-probability
0
1
0.1
0.01
1
NIL
HORIZONTAL

MONITOR
91
653
141
698
Day
days
0
1
11

MONITOR
23
653
80
698
Year
years
17
1
11

PLOT
821
826
1022
946
Deer Death by Natural Cause
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot natural-death-cause\n"

@#$#@#$#@
# 1. Model Design
## 1.1 Driving Question
What are the potential impacts of hunting as a population control measure on deer population dynamics and automobile accident rates involving deer, and how can these outcomes be simulated through an agent-based modelling approach?

## 1.2 Agents Properties
### Deer agents properties:
* Breed
* Age
* Gender 
* Pregnant/not pregnant (female deer only)
* Location
* Heading

### Hunter agents properties:
* Location 
* Heading
* Hunters' skill level 


### Car agents properties:
* Location
* Heading
* Speed
* Drivers' skill level 

## 1.3 Agents Behaviour
* Deer and hunters perform random walks.
* After reaching a certain age, deer agents will die.
* Male and female deer agents can mate, making the female deer pregnant. As long as the female deer survives, she will give birth to a new deer after a certain period of time  (gestation period, as determined by her breed).
* A hunter agent can harvest a deer agent, causing the deer to die.
* Cars move straight along the road they're on.
* A car agent can hit a deer agent, causing the deer to die.

## 1.4 Parameters
* Initial number of male and female deer
* Number of roads/length of roads
* Number of cars
* Number of hunters
* Start/end dates of hunting season
* Start/end dates of mating season
* Breed of deer
* Mating probability success rate
* Accident probabilty rate 
* Harvest probability rate

## 1.5 Measures
* Population of deer over time
* Deer harvested over time
* Number of car accidents involving deer over time

# 2. Model implementation

## WHAT IS IT?
This model simulates the effects of hunting on deer population and vehicle accident rates involving deer. The world, which forms the deer habitat, includes male deer in blue, female deer in pink, roads in gray bands and including cars, and, during hunting season, hunters in black. The world background color is displayed in light green in spring, dark green in summer, orange-brown in autumn, and white in winter.
 
## HOW IT WORKS
The deer population, all initially 2 years old, are randomly placed around the world and are set to wander randomly. During the mating season, if a female and male deer (aged at least 1 1/2 years old) occupy the same patch, then, based on a mating probability success rate, the female becomes pregnant. As time elapses, assuming the pregnant deer does not die, either by natural causes, hunters, or by accident with an automobile, the deer will give birth to either 1 or 2 randomly chosen offspring with randomly assigned gender.

During hunting season, hunters are randomly placed around the world and are set to wander randomly. If a hunter and a deer occupy the same patch, then, based on a harvesting probability rate, the hunters harvest the deer during a user-defined hunting season, thereby reducing the deer population.

The cars are randomly placed on the road(s) and are set to move horizontally along the road(s). If a car and a deer occupy the same patch, then, based on an accident probability rate, the car hits the deer, thereby reducing the deer population.

Because the cars move one patch per tick, time must be adjusted in the model by determining how many hours goes by for each tick in the simulation. Days in the model are determined by dividing the number of miles per patch of road by the average speed of the cars.

### Parameters
* SIZE-WORLD: Sets size of the world, where each whole unit represents 9000 square miles.
* NUM-ROAD: Sets the number of roads.
* NUM-CAR-PER-ROAD: Sets the number of cars for each road.
* AVERAGE-SPEED-CAR: Sets the average speed of the cars on the road.
* MILES-PER-ROAD: Sets the miles of road represented by each road. 
* ACCIDENT-PROBABILITY: Sets the probability that a car and a deer occupying same patch will be involved in an accident.
* NUM-FEMALE-DEER: Initializes the female deer population, where each unit represents 1000 deer.
* MATE-PROBABILITY: Sets the probability that a female deer and a male deer occupying same patch will successfully mate.
* BREED-DEER: Selects the deer breed (this sets, for example, the gestation period.
* NUM-HUNTER: Sets the hunter population, where each unit represents 1000 hunters.
* HARVEST-PROBABILITY: Sets the probability that a hunter will successfully harvest a deer occupying same patch.

## HOW TO USE IT
1. Adjust the input parameters (see above), or use the default settings (the default settings were calibrated to match actual numbers for the state of Pennsylvania for 2020-2021).
2. Press the SETUP button and a series of dialog boxes will appear, allowing the user to:
(1) enter an optional file name and location for saving the model output, 
(2) specify start and end dates of annual hunting season, and 
(3) specify the start and end dates of the annual mating season.
3. Press the GO button to start the simulation.

## THINGS TO NOTICE
* Watch the deer population grow or shrink on the monitor.
* See the seasons change.
* Notice the appearance of hunters during hunting season as well as the consequential decrease in deer population. 
* Witness car accidents involving deer.

## THINGS TO TRY
* Try altering the number of hunters and the duration of the hunting season, and notice its effect on the stability of deer population.
* Try altering the number of roads and cars, and notice its effect on the number of deer hits. 
* Turn on the reset-data-every-year? switch to reset the monitors every year.

## EXTENDING THE MODEL
* Add corn crop agents, which would, once eaten, give deer agents energy (if deer have too low energy level, then they would die) and could be used to assess the economical impacts deer have on crops (eating and/or damaging).
* Add a modify button that allows user to change parameters during the simulation.
* Add specific hunting seasons for female and male deer. 
* Add distribution functions, for example, to the gestation period or deer natural death rates, to more accurately model reality (e.g., deer aren't always pregnant for exactly x amount of days).
* Add variability in terrain (e.g., when a deer is going up a hill, its speed alters).


## NETLOGO Extensions
* The time extension was added to allow for calculating the number of days between the dates that the user inputs in.
* The csv extension was added to allow for important data from the simulation could be inserted in a csv file so that user can analyze the data using their program of choice. 

## RELATED MODELS
 * The wolf and sheep model in Netlogo's model library to the extent that both models model predators (hunters/wolves) and prey (deer/sheep).
 * "Estimating the effects of changes in harvest management on white-tailed deer (ODOCOILEOUS VIRGINIANUS) populations", Master's thesis by Van Burskirk, A. [1]: The author built a netlogo model to provide a tool for the assessment of deer density reduction programs. In particular, the author investigates “the effects of different deer densities, harvest rates of antlerless deer (female adults, female juveniles, and fawns), and sizes and shapes of deer removal areas on the ability to locally reduce deer densities.”


# 3. Execution and Analysis of Model
In order to explore the model, it is important to run multiple runs with the same parameter values to measure the randomness. In addition, it is important to also alter the parameter values to see how it affects the model. In this section, altering the number of hunters and their harvest probability rate was explored for five runs for each change in parameter value (see python jupyter notebook for more detail).

The parameter for the number of hunters and harvest probability was altered 4 times: high number of hunters and high harvest probability, high number of hunters and low harvest probability, low number of hunters and high harvest probability, and low number of hunters and low harvest probability.
## High number of hunters & high harvest probability
The following are the initial parameters:

![alt text](file:data_collection/hunt+_prob+.png)


## High number of hunters & low harvest probability
The following are the initial parameters:

![alt text](file:data_collection/hunt+_prob-.png)


## Low number of hunters & high harvest probability
The following are the initial parameters:

![alt text](file:data_collection/hunt-_prob+.png)


## Low number of hunters & low harvest probability
The following are the initial parameters:

![alt text](file:data_collection/hunt-_prob-.png)


## Visual representation of the data collected:
### Effect on deer population:
The following graphs illustrate the data collected from multiple runs (each color represents a different run):

![alt text](file:data_collection/population.png)

### Effect on deer involved in vehicular accidents:
The following graphs illustrate the data collected from multiple runs (each color represents a different run):

![alt text](file:data_collection/hit.png)

### Effect on number of deer harvested:
The following graphs illustrate the data collected from multiple runs (each color represents a different run):

![alt text](file:data_collection/harvest.png)

# 4. Verification and Validation of Model 
## Verification
A model verification is the process of determining whether an implemented model corresponds to the target conceptual model. This can be evaluated through sensitivity analysis and robustness. Based on the data collected from section 3, "Execution and Analysis of Model", the sensitivity of a change of parameter values can be effectively evaluated. 

It was clear that changing the number of hunters and their harvest probability rate affected the number of deer harvested, the number of deer involved in car accidents, and thereby, the overall deer population. As the number of hunters increased, the population of the deer decreased, leading to a decrease in car accidents involving deer; and obviously an increase in the number of deer harvested by hunters. The opposite happened when decreasing the number of hunters. Altering the harvest probability rate alone would have similar effects, but not as extreme. Interestingly enough, with a large number of hunters and a low probability of harvest (more realistic) the population stabilizes. This shows that the model is sensitive to the parameters but not in an extreme way. In addition, each run provided very similar results, implying that there isn't too much randomness.


## Validation
A model validation is the process of determining whether the implemented model corresponds to, and explains, some phenomenon in the real world. There are two levels at which the validation process is occuring: microvalidation and macrovalidation

Microvalidation is making sure the behaviours and mechanisms encoded into the agents in the model match up with their real-world analogs. It is hard to capture behaviours of deer, hunters, and cars in a model. For example, in my model, the deer and hunters perform a random walk. In reality it is much more complex than that. Deer and hunters might move based on many factors such as noise, areas that might be considered hot-spots for deer, where other deer might be situated, etc. 

Macrovalidation is the process of ensuring that the aggregate, emergent properties of the model correspond to aggregate properties in the real world. The fundamental idea is that as you increase the number of predators (in this case hunters and cars) the number of prey starts declining. This is true in the present model. The complexity of how it affects the population has been examined above in "3. Execution and Analysis of Model" and will be further examined when using real data from Pennsylvania, below.

As it is difficult to evaluate the microvalidation of the model, I will be focusing on the macrovalidation of the model and specifically perform empirical validation with Pennsylvania data to effectively validate the model.

## Using data from Pennsylvania
### Data gathered:
The following data was gathered from the Pennsylvania Game Commission, "Pennsylvania 2020-21 Deer Harvest Estimates" [2]:

![alt text](file:images/deer_harvest_report.png)

The following data was gathered from PennState College of Agricultral Sciences [3] and WildLife Informer [4]:

![alt text](file:images/deer_population_report.png)

The following data was gathered from Wikipedia page called "Pennsylvania" [5] and Pennsylvania Department of Transportation [6,7] :

![alt text](file:images/street_report.png)

According to the Pennsylvania Game Commision, the hunting season for 2019-2020 was November 30th to December 14th, and for 2020-2021 was November 28th to December 12th [8,9]. 

Finally, according to  Pennsylvania Game Commision, the typical mating season for deer in Pennsylvania is December to February [10] 

### For 2019-2020:
#### Inserting models known parameters using Pennsylvania data:

* SIZE-WORLD: 5 (45000 square miles)
* NUM-ROAD: 1
* MILES-PER-ROAD: 121000 (miles)
* NUM-MALE-DEER: 375 (375,000 male deer)
* NUM-FEMALE-DEER: 1125 (1,125,000 female deer)
* BREED-DEER: White-tail
* NUM-HUNTER: 633 (633,000 hunters) 
* HARVEST-PROBABILITY: 0.25 (25%)

#### Inserting models unknown parameters:
The decision of what the other parameters should be is based on what would make sense and also what fits the best:

* NUM-CAR-PER-ROAD: 2 
* AVERAGE-SPEED-CAR: 31 (miles per hour)
* ACCIDENT-PROBABILITY: 0.10 (10%)
* MATE-PROBABILITY: 0.20 (20%)

### For 2020-2021:
#### Inserting models parameters:
Note that the inputted deer population parameter is from the results of the end of the 2019-2020 simulation:

* SIZE-WORLD: 5 (45000 square miles)
* NUM-ROAD: 1
* NUM-CAR-PER-ROAD: 2 
* AVERAGE-SPEED-CAR: 31 (miles per hour)
* ACCIDENT-PROBABILITY: 0.10 (10%)
* MILES-PER-ROAD: 121000 (miles)
* NUM-MALE-DEER: 478 (478,000 male deer)
* NUM-FEMALE-DEER: 1071 (1,071,000 female deer)
* MATE-PROBABILITY: 0.20 (20%) 
* BREED-DEER: White-tail
* NUM-HUNTER: 633 (633,000 hunters) 
* HARVEST-PROBABILITY: 0.27 27(%)


#### Results from simulation of the model:
5 runs of the simulation were performed to account for randomness. To see the results from the individual runs, check out their csv file and the analysis on the python notebook file.

The following is a table of the results:

![alt text](file:images/model_results.png)

The following graph compares deer population growth simulated for 2019-2020 and 2020-2021:

![alt text](file:images/model_result_pop.png)

The following compares the simulated number of deer involved in vehicular accidents in 2019-2020 and 2020-2021 and the true number gathered from Pennsylvania data:

![alt text](file:images/model_result_hit.png)

The following compares the simulated number of harvested deer in 2019-2020 and 2020-2021 and the true number from Pennsylvania data:

![alt text](file:images/model_result_har.png)

As can be seen above, the simulation has fairly well predicted the true values. This indicates that the simulation could be applied to other states or even countries. It could valuable insights on how different parameters and their values, affect deer population, number of harvested deer, and the number of deer involved in vehicular accidents. 

They're, of course, limitations to this model, as with any model: over simplification of reality. It doesn't consider different hunting season for antlered and antlerness deer, the effect of terrain and season on the deer, hunters, and even cars, the complexity of the road layout in a large environment, etc.

All in all, using the Pennsylvania data collected through a number of sources, has provided validation to the model/simulation and its accuracy in simulating deer population, number of deer involved in vehicular accident, and deer harvested.




# REFERENCES

1. Van Buskirk, A. (2020). ESTIMATING THE EFFECTS OF CHANGES IN HARVEST MANAGEMENT ON WHITE-TAILED DEER (ODOCOILEOUS VIRGINIANUS) POPULATIONS. [Pdf] Available at: https://etda.libraries.psu.edu/files/final_submissions/21979 (Accessed 1 Mar. 2023).
2. (2023) Pgc.pa.gov. Available at: https://www.pgc.pa.gov/Wildlife/WildlifeSpecies/White-tailedDeer/Documents/2021%20Harvest%20Estimates%20Report%2020210329.pdf (Accessed: 15 March 2023).
3. Dreams (2022). Available at: https://www.deer.psu.edu/dreams/ (Accessed: 15 March 2023).
4. Wildlife Informer (2022) Deer population by state (estimates and info), Wildlife Informer. Available at: https://wildlifeinformer.com/deer-population-by-state/ (Accessed: March 15, 2023). 
5. "Pennsylvania - Wikipedia". En.Wikipedia.Org, 2023, https://en.wikipedia.org/wiki/Pennsylvania. (Accessed 15 Mar 2023).
6. (2023) Dot.state.pa.us. Available at: https://www.dot.state.pa.us/public/PubsForms/Publications/PUB%20410.pdf (Accessed: 15 March 2023).
7. Crash Facts & Statistics (2023). Available at: https://www.penndot.pa.gov/TravelInPA/Safety/Pages/Crash-Facts-and-Statistics.aspx (Accessed: 15 March 2023).
8. Game Commission Details (2019). Available at: https://www.media.pa.gov/Pages/Game-Commission-Details.aspx?newsid=301#:~:text=The%20Board%20of%20Game%20Commissioners,in%2020%20Wildlife%20Management%20Units. (Accessed: 15 March 2023).
9. Game Commission Details (2020). Available at: https://www.media.pa.gov/Pages/Game-Commission-Details.aspx?newsid=381 (Accessed: 15 March 2023).
10. When is the rut? (2023). Available at: https://www.pgc.pa.gov/Wildlife/WildlifeSpecies/White-tailedDeer/Pages/Whenistherut.aspx (Accessed: 15 March 2023).





@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

deer
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -6459832 true false 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -6459832 true false -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113
Polygon -7500403 true true 240 105 240 60
Polygon -6459832 true false 240 105 225 105 180 60 150 75 180 60 195 30 195 60 210 45 210 75 225 60 225 75 240 90 255 90 255 105 240 105 240 105 225 105 180 60 165 60 180 60
Rectangle -13345367 true false 90 150 180 180

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

female deer
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -6459832 true false 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -6459832 true false -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113
Polygon -7500403 true true 240 105 240 60
Polygon -6459832 true false 240 105 225 105 180 60 150 75 180 60 195 30 195 60 210 45 210 75 225 60 225 75 240 90 255 90 255 105 240 105 240 105 225 105 180 60 165 60 180 60
Rectangle -2064490 true false 90 150 180 180

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
