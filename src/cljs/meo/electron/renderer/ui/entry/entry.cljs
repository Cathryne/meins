(ns meo.electron.renderer.ui.entry.entry
  (:require [meo.electron.renderer.ui.leaflet :as l]
            [meo.electron.renderer.ui.mapbox :as mb]
            [meo.electron.renderer.ui.media :as m]
            [re-frame.core :refer [subscribe]]
            [reagent.ratom :refer-macros [reaction]]
            [meo.common.utils.parse :as up]
            [meo.electron.renderer.ui.entry.actions :as a]
            [taoensso.timbre :refer-macros [info error debug]]
            [meo.electron.renderer.ui.entry.location :as loc]
            [meo.electron.renderer.ui.entry.capture :as c]
            [meo.electron.renderer.ui.entry.task :as task]
            [meo.electron.renderer.ui.entry.habit :as habit]
            [meo.electron.renderer.ui.entry.reward :as reward]
            [meo.electron.renderer.ui.entry.story :as es]
            [meo.electron.renderer.ui.entry.utils :as eu]
            [meo.electron.renderer.ui.entry.carousel :as carousel]
            [meo.electron.renderer.ui.entry.wavesurfer :as ws]
            [meo.common.utils.misc :as u]
            [meo.electron.renderer.helpers :as h]
            [meo.electron.renderer.ui.draft :as d]
            [clojure.set :as set]
            [moment]
            [meo.electron.renderer.ui.entry.pomodoro :as pomo]
            [clojure.pprint :as pp]
            [reagent.core :as r]))

(defn all-comments-set [ts]
  (let [{:keys [entry new-entries]} (eu/entry-reaction ts)
        comments-filter (fn [[_ts c]] (= (:comment-for c) ts))
        local-comments (reaction (into {} (filter comments-filter @new-entries)))]
    (reaction (sort (set/union (set (:comments @entry))
                               (set (keys @local-comments)))))))

(defn hashtags-mentions-list [ts tab-group put-fn]
  (let [entry (:entry (eu/entry-reaction ts))]
    (fn hashtags-mentions-render [ts tab-group put-fn]
      [:div.hashtags
       (for [mention (:mentions @entry)]
         ^{:key (str "tag-" mention)}
         [:span.mention {:on-click (up/add-search mention tab-group put-fn)}
          mention])
       (for [hashtag (set/union (:tags @entry) (:perm-tags @entry))]
         ^{:key (str "tag-" hashtag)}
         [:span.hashtag {:on-click (up/add-search hashtag tab-group put-fn)}
          hashtag])])))

(defn linked-btn [entry local-cfg active put-fn]
  (when (pos? (:linked-cnt entry))
    (let [ts (:timestamp entry)
          tab-group (:tab-group local-cfg)
          open-linked (up/add-search (str "l:" ts) tab-group put-fn)
          entry-active? (when-let [query-id (:query-id local-cfg)]
                          (= (query-id @active) ts))]
      [:div
       [:span.link-btn {:on-click open-linked
                        :class    (when entry-active? "active")}
        (str " linked: " (:linked-cnt entry))]])))

(defn conflict-view [entry put-fn]
  (let []
    (fn [entry put-fn]
      (when-let [conflict (:conflict entry)]
        [:div.conflict
         [:div.warn [:span.fa.fa-exclamation] "Conflict"]
         [:pre [:code (with-out-str (pp/pprint conflict))]]]))))

(defn git-commit [_entry _put-fn]
  (let [repos (subscribe [:repos])]
    (fn [entry put-fn]
      (when-let [git-commit (:git-commit @entry)]
        (let [{:keys [repo-name refs commit subject]} git-commit
              cfg (get-in @repos [repo-name])
              url (str
                    (:repo-url cfg) "/commit/" commit)]
          [:div.git-commit
           [:span.repo-name (str repo-name ":")]
           "["
           [:a {:href url :target "_blank"}
            (:abbreviated-commit git-commit)]
           "] "
           (when (seq refs) (str "(" refs ") "))
           subject])))))

(defn journal-entry
  "Renders individual journal entry. Interaction with application state happens
   via messages that are sent to the store component, for example for toggling
   the display of the edit mode or showing the map for an entry. The editable
   content component used in edit mode also sends a modified entry to the store
   component, which is useful for displaying updated hashtags, or also for
   showing the warning that the entry is not saved yet."
  [entry2 put-fn local-cfg]
  (let [ts (:timestamp entry2)
        cfg (subscribe [:cfg])
        {:keys [entry edit-mode new-entry entries-map]} (eu/entry-reaction ts)
        show-map? (reaction (contains? (:show-maps-for @cfg) ts))
        active (reaction (:active @cfg))
        backend-cfg (subscribe [:backend-cfg])
        q-date-string (.format (moment ts) "YYYY-MM-DD")
        tab-group (:tab-group local-cfg)
        add-search (up/add-search q-date-string tab-group put-fn)
        drop-fn (a/drop-linked-fn entry entries-map cfg put-fn)
        toggle-edit #(if @edit-mode (put-fn [:entry/remove-local @entry])
                                    (put-fn [:entry/update-local @entry]))
        local (r/atom {:scroll-disabled true})]
    (fn journal-entry-render [entry2 put-fn local-cfg]
      (let [entry2 (merge entry2 @new-entry)
            edit-mode? @edit-mode
            locale (:locale @cfg :en)
            formatted-time (h/localize-datetime (moment ts) locale)
            mapbox-token (:mapbox-token @backend-cfg)
            qid (:query-id local-cfg)
            map-id (str ts (when qid (name qid)))]
        [:div.entry {:on-drop       drop-fn
                     :on-drag-over  h/prevent-default
                     :on-drag-enter h/prevent-default}
         [:div.header-1
          [:div
           [es/story-select entry2 put-fn]
           [es/saga-select @entry put-fn edit-mode?]]
          [loc/geonames entry put-fn]]
         [:div.header
          [:div
           [:a [:time {:on-click add-search} formatted-time]]
           [:time (u/visit-duration entry2)]]
          [linked-btn entry2 local-cfg active put-fn]
          [a/entry-actions entry2 put-fn edit-mode? toggle-edit local-cfg]]
         [es/story-name-field entry2 edit-mode? put-fn]
         [es/saga-name-field entry2 edit-mode? put-fn]
         [d/entry-editor ts put-fn]
         [task/task-details @entry local-cfg put-fn edit-mode?]
         [habit/habit-details @entry local-cfg put-fn edit-mode?]
         [reward/reward-details @entry put-fn]
         [:div.footer
          [pomo/pomodoro-header entry edit-mode? put-fn]
          [hashtags-mentions-list ts tab-group put-fn]
          [:div.word-count (u/count-words-formatted entry2)]]
         [conflict-view entry2 put-fn]
         [c/custom-fields-div @entry put-fn edit-mode?]
         [git-commit entry put-fn]
         [ws/wavesurfer @entry local-cfg put-fn]
         (when @show-map?
           (if mapbox-token
             [:div.entry-mapbox
              {:on-click #(swap! local update-in [:scroll-disabled] not)}
              [mb/mapbox-cls {:local           local
                              :id              map-id
                              :selected        entry2
                              :scroll-disabled (:scroll-disabled @local)
                              :local-cfg       local-cfg
                              :mapbox-token    mapbox-token
                              :put-fn          put-fn}]]
             [l/leaflet-map entry2 @show-map? local-cfg put-fn]))
         ;[m/image-view entry]
         ;[m/videoplayer-view @entry]
         [m/imdb-view @entry put-fn]
         [m/spotify-view @entry put-fn]
         [c/questionnaire-div @entry put-fn edit-mode?]]))))

(defn entry-with-comments
  "Renders individual journal entry. Interaction with application state happens
   via messages that are sent to the store component, for example for toggling
   the display of the edit mode or showing the map for an entry. The editable
   content component used in edit mode also sends a modified entry to the store
   component, which is useful for displaying updated hashtags, or also for
   showing the warning that the entry is not saved yet."
  [entry2 put-fn local-cfg]
  (let [ts (:timestamp entry2)
        {:keys [entry new-entries]} (eu/entry-reaction ts)
        all-comments-set (all-comments-set ts)
        cfg (subscribe [:cfg])
        options (subscribe [:options])
        show-pvt? (reaction (:show-pvt @cfg))
        entries-map (subscribe [:entries-map])
        comments (reaction
                   (let [comments (map (fn [ts]
                                         (or (get @new-entries ts)
                                             (get @entries-map ts)))
                                       @all-comments-set)
                         pvt-filter (u/pvt-filter @options @entries-map)
                         comments (if @show-pvt?
                                    comments
                                    (filter pvt-filter comments))]
                     (map :timestamp comments)))

        thumbnails? (reaction (and (not (contains? (:tags @entry) "#briefing"))
                                   (:thumbnails @cfg)))
        show-comments-for? (reaction (get-in @cfg [:show-comments-for ts]))
        query-id (:query-id local-cfg)
        toggle-comments #(put-fn [:cmd/assoc-in
                                  {:path  [:cfg :show-comments-for ts]
                                   :value (when-not (= @show-comments-for? query-id)
                                            query-id)}])]
    (fn entry-with-comments-render [entry2 put-fn local-cfg]
      (let [comments (:comments entry2)]
        ;(info comments)
        [:div.entry-with-comments
         [journal-entry entry2 put-fn local-cfg]
         (when @thumbnails? [carousel/gallery entry local-cfg put-fn])
         (when (seq comments)
           (if (= query-id @show-comments-for?)
             [:div.comments
              (let [n (count comments)]
                [:div.show-comments
                 (when (pos? n)
                   [:span {:on-click toggle-comments}
                    (str "hide " n " comment" (when (> n 1) "s"))])])
              (for [comment comments]
                ^{:key (str "c" comment)}
                [journal-entry comment put-fn local-cfg])]
             [:div.show-comments
              (let [n (count comments)]
                [:span {:on-click toggle-comments}
                 (str "show " n " comment" (when (> n 1) "s"))])]))]))))
