(ns meo.vclock-test
  (:require [clojure.test :refer :all]
            [meo.common.utils.vclock :as vc]))

(def some-node-id "some-node-id")
(def another-node-id "another-node-id")
(def yet-another-node-id "yet-another-node-id")

(deftest new-global-vclock-test
  (testing "returns latest vclock values"
    (is (= {some-node-id    2
            another-node-id 1}
           (vc/new-global-vclock
             {some-node-id    1
              another-node-id 1}
             {:vclock {some-node-id 2}}))))

  (testing "returns original vclock when entry already known"
    (is (= {some-node-id    2
            another-node-id 1}
           (vc/new-global-vclock
             {some-node-id    2
              another-node-id 1}
             {some-node-id 2}))))

  (testing "ignores non-numbers"
    (is (= {some-node-id    2
            another-node-id 1}
           (vc/new-global-vclock
             {some-node-id    2
              another-node-id 1}
             {some-node-id :foo})))))

(deftest next-global-vclock-test
  (testing "next global vclock state is generated correctly"
    (is (= {another-node-id 1
            some-node-id    3}
           (vc/next-global-vclock
             {:cfg           {:node-id some-node-id}
              :global-vclock {some-node-id    2
                              another-node-id 1}}))))

  (testing "add node id when not known yet"
    (is (= {another-node-id       1
            some-node-id          2
            "yet-another-node-id" 1}
           (vc/next-global-vclock
             {:cfg           {:node-id "yet-another-node-id"}
              :global-vclock {some-node-id    2
                              another-node-id 1}})))))

(deftest set-latest-vclock-test
  (testing "vclock set correctly"
    (is (= {:vclock {some-node-id 2}}
           (vc/set-latest-vclock
             {:vclock {some-node-id 2}}
             some-node-id
             {some-node-id 2})))))

(deftest vclock-comparator-test

  (testing "return :equal when both clocks are the same"
    (is (= :equal
           (vc/vclock-comparator
             {some-node-id    1
              another-node-id 2}
             {some-node-id    1
              another-node-id 2}))))

  (testing "returns :conflict when there is a conflict"
    (is (= :concurrent
           (vc/vclock-comparator
             {some-node-id    2
              another-node-id 1}
             {some-node-id    1
              another-node-id 2}))))

  (testing "returns :a>b when A dominates B"
    (is (= :a>b
           (vc/vclock-comparator
             {some-node-id    2
              another-node-id 1}
             {some-node-id    1
              another-node-id 1}))))

  (testing "returns :b>a when B dominates A"
    (is (= :a>b
           (vc/vclock-comparator
             {some-node-id    2
              another-node-id 1}
             {some-node-id    1
              another-node-id 1}))))

  (testing "returns :b>a when B dominates A via additional node"
    (is (= :b>a
           (vc/vclock-comparator
             {some-node-id    2
              another-node-id 1}
             {some-node-id        2
              another-node-id     1
              yet-another-node-id 3}))))

  (testing "returns :conflict both A updated and B has a previously unknown node"
    (is (= :concurrent
           (vc/vclock-comparator
             {some-node-id    3
              another-node-id 1}
             {some-node-id        2
              another-node-id     1
              yet-another-node-id 3}))))

  (testing "throws exception if A is invalid"
    (is (thrown? Exception
                 (vc/vclock-comparator
                   {:foo 1
                    3    "a"}
                   {some-node-id        2
                    another-node-id     1
                    yet-another-node-id 3}))))

  (testing "throws exception if B is invalid"
    (is (thrown? Exception
                 (vc/vclock-comparator
                   {some-node-id        2
                    another-node-id     1
                    yet-another-node-id 3}
                   {:foo 1
                    3    "a"})))))
