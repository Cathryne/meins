# iWasWhere

**iWasWhere** is a **personal information manager**, with a **geo-aware diary** or **log** and **task tracking**. It allows me to make sense of where I was and what I did there.


## Motivation

Over the course of the past twenty years, I've traveled the globe a lot, usually multiple times every year. But do I know where I was exactly 10 or 15 years ago? Oh no, even one year ago I have no clue. I have vague ideas about the places I have visited, but I probably won't even be able to pinpoint the exact year. That's not enough. See, life won't go well forever. There absolutely will come a time when I won't be able to travel nearly as much. Would I then want to settle with faded memories of the past? No, most certainly not.

I recently had tea with my 92-year-old grandma, and we were looking at her collection of photographs. I later noticed that she had a handwritten list of the places she had been to, with the exact dates, who with, and some brief notes about the occasion. I wish I was also keeping records of every aspect of my life, but unfortunately my handwriting is terrible so it would have to be done electronically. 

Then I decided to build an application that will provide me with the tools to plan (and record) my life better. It should allow me to write down every thought, note, photo, video or whatnot while keeping track of the location. In addition, I should be able to **retrieve information** so that I can always find anything later on. Since there will be a lot of private information that will accumulate over time, the data should not be stored in the cloud but rather locally.

**iWasWhere** is what I came up with as a solution. I use it every day and I have so far recorded over **4,200** entries, in about 10 weeks. It is also a suitable sample application for my book **[Building a System in Clojure](https://leanpub.com/building-a-system-in-clojure)**. As a bonus, it could also be useful for anyone who would like to keep a record of their thoughts, ideas, and projects, all while recording the exact whereabouts on what took place and where it happened.


## Components

**iWasWhere** consists of a **[Clojure](https://clojure.org/)** and **[ClojureScript](https://github.com/clojure/clojurescript)** system spanning the **browser** and a backend that runs on the **[JVM](https://en.wikipedia.org/wiki/Java_virtual_machine)**. This project lives in the **[iwaswhere-web](https://github.com/matthiasn/iWasWhere/tree/master/iwaswhere-web)** directory, which is also where you can find installation instructions and more information about the system's architecture.

There's also an **iOS app** that keeps track of visits and lets me quickly capture thoughts on the go. Currently, it's a very basic application written in **[Swift](https://swift.org/)**. It is not open sourced yet, but that will happen in due course. Ideally, by then it should also have been rewritten in **ClojureScript** and **[React Native](https://facebook.github.io/react-native/)**. Stay tuned.


## License

Copyright © 2016 **[Matthias Nehlsen](http://www.matthiasnehlsen.com)**. Distributed under the **GNU GENERAL PUBLIC LICENSE**, Version 3. See separate LICENSE files in sub-projects.
