int gcd(int a, int b) {
  while (a != b) {
    if (a > b) {
      a = a - b;
    }
    else {
      b = b - a;
    }
  }
  return a;
}

int main() {
  //int result = gcd(272,1479); // 17
  int result = gcd(6,4);
  if(result == 2) {
    while(1);
  }
  return 0;
}
