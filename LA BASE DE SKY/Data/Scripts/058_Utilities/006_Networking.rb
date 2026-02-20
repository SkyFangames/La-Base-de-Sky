# Check if internet connection is available
def network_available?
  begin
    # Try a simple HTTP request using HTTPLite to check connectivity
    response = HTTPLite.get("http://httpbin.org/status/200")
    return response && response.fetch(:status) == 200
  rescue StandardError
    return false
  end
end