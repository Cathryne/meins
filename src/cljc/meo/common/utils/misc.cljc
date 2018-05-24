(ns meo.common.utils.misc
  (:require [clojure.string :as s]
            [clojure.set :as set]
            [taoensso.timbre :refer-macros [info debug]]
            [meo.common.specs :as specs]))

(defn duration-string
  "Format duration string from seconds."
  [seconds]
  (let [hours (int (/ seconds 3600))
        seconds (rem seconds 3600)
        min (int (/ seconds 60))
        sec (int (rem seconds 60))]
    (s/trim
      (str (when (pos? hours) (str hours "h "))
           (when (pos? min) (str min "m "))
           (when (pos? sec) (str sec "s"))))))

(defn visit-duration
  "Formats duration string."
  [entry]
  (let [arrival-ts (:arrival-timestamp entry)
        depart-ts (:departure-timestamp entry)
        secs (when (and arrival-ts depart-ts)
               (let [dur (- depart-ts arrival-ts)]
                 (if (int? dur) (/ dur 1000) dur)))]
    (when (and secs (< secs 99999999))
      (str ", " (duration-string secs)))))

(defn pvt-filter
  "Filter for entries considered private."
  [options]
  (fn [entry]
    (let [tags (set (map s/lower-case (:tags entry)))
          private-tags (:pvt-hashtags options)
          hashtags (:hashtags options)
          only-pvt-tags (set/difference private-tags hashtags)
          matched (set/intersection tags only-pvt-tags)]
      (empty? matched))))

(defn suggestions
  "Renders suggestions for hashtags or mentions if either occurs before the
   current caret position. It does so by getting the selection from the DOM API,
   which can be used to determine the position and a string before that
   position, then finding either a hashtag or mention fragment right at the end
   of that substring. For these, auto-suggestions are displayed, which are
   entities that begin with the tag fragment before the caret position. When any
   of the suggestions are clicked, the fragment will be replaced with the
   clicked item."
  [key-prefix filtered-tags current-tag tag-replace-fn css-class]
  (when (seq filtered-tags)
    [:div.suggestions
     [:div.suggestions-list
      (for [tag filtered-tags]
        ^{:key (str key-prefix tag)}
        [:div {:on-click #(tag-replace-fn current-tag tag)}
         [:span {:class css-class} tag]])]]))

(defn double-ts-to-long
  [ts]
  (when (and ts (number? ts))
    (long (* ts 1000))))

(defn visit-timestamps
  "Parse arrival and departure timestamp as milliseconds since epoch."
  [entry]
  (let [departure-ts (let [ms (double-ts-to-long (:departure-timestamp entry))]
                       (when (specs/possible-timestamp? ms) ms))]
    {:arrival-ts   (double-ts-to-long (:arrival-timestamp entry))
     :departure-ts departure-ts}))

(defn count-words
  "Naive implementation of a wordcount function."
  [entry]
  (if-let [text (:md entry)]
    (count (filter seq (s/split text #"\s")))
    0))

(defn count-words-formatted
  "Generate wordcount string."
  [entry]
  (let [cnt (count-words entry)]
    (when (> cnt 20)
      (str cnt " words"))))

(defn deep-merge
  "Deep merge for multiple maps."
  [& maps]
  (let [maps (filter identity maps)]
    (when (seq maps)
      (apply (fn m [& maps]
               (if (every? map? maps)
                 (apply merge-with m maps)
                 (apply (fn [_ b] b) maps)))
             maps))))

(defn clean-entry
  "Removes keys from entry that are not meant to be persisted."
  [entry]
  (-> entry
      (dissoc :comments)
      (dissoc :new-entry)
      (dissoc :linked)
      (dissoc :linked-cnt)
      (dissoc :last-saved)
      (dissoc :vclock)
      (dissoc :story)
      (update-in [:task] dissoc :completed-s)
      (update-in [:task] dissoc :due)
      (update-in [:tags] set)
      (dissoc :editor-state)
      (dissoc :pomodoro-running)
      (dissoc :linked-entries-list)))

(defn linked-filter-fn
  "Filter linked entries by search."
  [entries-map linked-filter put-fn]
  (fn [entry]
    (let [comments (:comments entry)
          combined-tags (reduce #(set/union %1 (:tags %2)) (:tags entry) comments)]
      (and (set/subset? (:tags linked-filter) combined-tags)
           (empty? (set/intersection (:not-tags linked-filter)
                                     combined-tags))))) )

(defn search-from-cfg [state] (select-keys (:query-cfg state) #{:queries}))

(defn cleaned-queries [state]
  (->> state
       :query-cfg
       :queries
       (map (fn [[k v]] [k (dissoc v :editor-state)]))
       (into {})))
