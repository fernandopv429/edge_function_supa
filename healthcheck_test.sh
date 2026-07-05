if curl --max-time 2 -s -o /dev/null http://127.0.0.1:9999/; then
  echo "Success"
else
  echo "Fail"
fi
