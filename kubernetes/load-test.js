import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '2m', target: 50 },
    { duration: '2m', target: 100 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
  },
};

export default function () {
  const response = http.get('http://k8s-petclini-petclini-8cd69a76f1-527816886.eu-north-1.elb.amazonaws.com/');

  check(response, {
    'status is 200': (r) => r.status === 200,
  });

  sleep(1);
}