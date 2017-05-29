package main

import (
	"encoding/json"
	"log"
	"os"
	"net/http"

	"github.com/xanzy/go-gitlab"
	authentication "k8s.io/client-go/pkg/apis/authentication/v1beta1"
)

func main() {
	log.Println("Gitlab Authn Webhook:", os.Getenv("GITLAB_API_ENDPOINT"))
	http.HandleFunc("/authenticate", func(w http.ResponseWriter, r *http.Request) {
		decoder := json.NewDecoder(r.Body)
		var tr authentication.TokenReview
		err := decoder.Decode(&tr)
		if err != nil {
			log.Println("[Error]", err.Error())
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"apiVersion": "authentication.k8s.io/v1beta1",
				"kind":       "TokenReview",
				"status": authentication.TokenReviewStatus{
					Authenticated: false,
				},
			})
			return
		}

		client := gitlab.NewClient(nil, tr.Spec.Token)
		client.SetBaseURL(os.Getenv("GITLAB_API_ENDPOINT"))

		// Get user
		user, _, err := client.Users.CurrentUser()
		if err != nil {
			log.Println("[Error]", err.Error())
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"apiVersion": "authentication.k8s.io/v1beta1",
				"kind":       "TokenReview",
				"status": authentication.TokenReviewStatus{
					Authenticated: false,
				},
			})
			return
		}

		// Get user's group
		groups, _, err := client.Groups.ListGroups(nil)
		if err != nil {
			log.Println("[Error]", err.Error())
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"apiVersion": "authentication.k8s.io/v1beta1",
				"kind":       "TokenReview",
				"status": authentication.TokenReviewStatus{
					Authenticated: false,
				},
			})
			return
		}

		all_group_path := make([]string, len(groups))
    for i, g := range groups {
        all_group_path[i] = g.Path
    }

		// Set the TokenReviewStatus
		log.Printf("[Success] login as %s, groups: %v", user.Username, all_group_path)
		w.WriteHeader(http.StatusOK)
		trs := authentication.TokenReviewStatus{
			Authenticated: true,
			User: authentication.UserInfo{
				Username: user.Username,
				UID:      user.Username,
				Groups: all_group_path,
			},
		}
		json.NewEncoder(w).Encode(map[string]interface{}{
			"apiVersion": "authentication.k8s.io/v1beta1",
			"kind":       "TokenReview",
			"status":     trs,
		})
	})
	log.Fatal(http.ListenAndServe(":3000", nil))
}
