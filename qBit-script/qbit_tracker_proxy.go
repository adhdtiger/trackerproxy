package main

import (
  "bytes"
  "encoding/json"
  "fmt"
  "io"
  "log"
  "net/http"
  "net/url"
  "os"
  "strings"
)

const (
  base = "http://localhost:8080"
)

var (
  from = []string{"https://t.myanonamouse.net/tracker.php", "https://tracker.foo.org", "https://tracker.bar.org"}
  to   = []string{"http://localhost/mam/tracker.php", "http://localhost/foo", "http://localhost/bar"}
)

type Torrent struct {
  Hash    string `json:"hash"`
  Tracker string `json:"tracker,omitempty"`
}

type Tracker struct {
  URL string `json:"url"`
}

func main() {
  if len(os.Args) == 1 {
    update_all_torrents()
  } else if len(os.Args) == 2 {
    update_torrent(os.Args[1])
  } else {
    log.Fatal("Error! Expected 0 or 1 arguments")
  }
}

func update_torrent(hash string) {
  trackers, err := get_trackers(hash)
  if err != nil {
    fmt.Println("Error getting trackers:", err)
    return
  }
  var old_tracker string
  for _, tracker := range trackers {
    for i, f := range from {
      if strings.HasPrefix(tracker.URL, f) {
        old_tracker = tracker.URL
        new_tracker := strings.ReplaceAll(old_tracker, f, to[i])
        _, err = edit_tracker(hash, old_tracker, new_tracker)
        if err != nil {
          fmt.Println("Error editing tracker:", err)
        }
        break
      }
    }
  }
}

func update_all_torrents() {
  torrents, err := list_torrents()
  if err != nil {
    fmt.Println("Error listing torrents:", err)
    return
  }

  var missing_tracker []*Torrent
  for _, torrent := range torrents {
    if torrent.Tracker == "" {
      missing_tracker = append(missing_tracker, torrent)
    }
  }

  for i := range missing_tracker {
    trackers, err := get_trackers(missing_tracker[i].Hash)
    if err != nil {
      fmt.Println("Error getting trackers:", err)
      return
    }
    for _, tracker := range trackers {
      for j, f := range from {
        if strings.HasPrefix(tracker.URL, f) {
          missing_tracker[i].Tracker = tracker.URL
          break
        }
      }
    }
  }

  var selected_torrents []*Torrent
  for _, torrent := range torrents {
    for _, f := range from {
      if strings.HasPrefix(torrent.Tracker, f) {
        selected_torrents = append(selected_torrents, torrent)
        break
      }
    }
  }
  fmt.Println("Updating", len(selected_torrents), "torrents")

  for _, torrent := range selected_torrents {
    for i, f := range from {
      if strings.HasPrefix(torrent.Tracker, f) {
        new_tracker := strings.ReplaceAll(torrent.Tracker, f, to[i])
        _, err := edit_tracker(torrent.Hash, torrent.Tracker, new_tracker)
        if err != nil {
          fmt.Println("Error editing tracker:", err)
        }
        break
      }
    }
  }
}

func list_torrents() ([]*Torrent, error) {
  resp, err := http.Get(fmt.Sprintf("%s/api/v2/torrents/info", base))
  if err != nil {
    return nil, err
  }
  defer resp.Body.Close()
  err = check_response(resp)
  if err != nil {
    return nil, err
  }

  var torrents []*Torrent
  err = json.NewDecoder(resp.Body).Decode(&torrents)
  if err != nil {
    return nil, err
  }
  return torrents, nil
}

func get_trackers(hash string) ([]Tracker, error) {
  resp, err := http.Get(fmt.Sprintf("%s/api/v2/torrents/trackers?hash=%s", base, hash))
  if err != nil {
    return nil, err
  }
  defer resp.Body.Close()
  err = check_response(resp)
  if err != nil {
    return nil, err
  }

  var trackers []Tracker
  err = json.NewDecoder(resp.Body).Decode(&trackers)
  if err != nil {
    return nil, err
  }
  return trackers, nil
}

func edit_tracker(hash, origURL, newURL string) (string, error) {
  data := url.Values{}
  data.Set("hash", hash)
  data.Set("origUrl", origURL)
  data.Set("newUrl", newURL)

  resp, err := http.Post(fmt.Sprintf("%s/api/v2/torrents/editTracker", base), "application/x-www-form-urlencoded; charset=UTF-8", bytes.NewBufferString(data.Encode()))
  if err != nil {
    return "", err
  }
  defer resp.Body.Close()
  return check_response_text(resp)
}

func check_response(resp *http.Response) error {
  if resp.StatusCode != http.StatusOK {
    body, _ := io.ReadAll(resp.Body)
    fmt.Printf("Error calling %s: %d\n", resp.Request.URL, resp.StatusCode)
    fmt.Println(string(body))
    return fmt.Errorf("request error")
  }
  return nil
}

func check_response_text(resp *http.Response) (string, error) {
  if resp.StatusCode != http.StatusOK {
    body, _ := io.ReadAll(resp.Body)
    fmt.Printf("Error calling %s: %d\n", resp.Request.URL, resp.StatusCode)
    fmt.Println(string(body))
    return "", fmt.Errorf("request error")
  }
  body, err := io.ReadAll(resp.Body)
  if err != nil {
    return "", err
  }
  return string(body), nil
}